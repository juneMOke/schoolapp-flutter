import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_status_visuals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La chaîne de validation (spec §01) : où en est la demande, en **trois
/// jalons** — demandée, décidée, payée.
///
/// Une seule chaîne, sans seuil ni palier : une demande de 15 $ et une de
/// 900 $ suivent le même chemin. Un refus ou un retrait n'ouvre pas de
/// quatrième colonne — il **prend la place** du jalon de décision et éteint
/// celui du paiement, parce que la demande ne le franchira pas.
class ExpenseChain extends StatelessWidget {
  final Expense expense;

  const ExpenseChain({super.key, required this.expense});

  /// L'ordre nominal du circuit ; la position de l'état y donne le nombre de
  /// jalons franchis.
  static const List<ExpenseStatus> _line = [
    ExpenseStatus.pending,
    ExpenseStatus.approved,
    ExpenseStatus.paid,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final status = expense.status;
    // Hors chaîne : la demande a quitté le chemin nominal, sans le remonter.
    final aside =
        status == ExpenseStatus.refused || status == ExpenseStatus.retracted;
    final reached = aside ? 0 : _line.indexOf(status);
    final decided = expense.decidedAt;
    final paidOn = expense.paidOn;

    String? when(DateTime? moment, String? who) {
      if (moment == null) return null;
      final day = dates.formatShortMonthDay(moment.toLocal());
      return who == null ? day : l10n.expenseJoin(day, who);
    }

    final milestones = <_Milestone>[
      _Milestone(
        label: l10n.expenseChainRequested,
        icon: Icons.send_outlined,
        // La date du dépôt n'a pas encore de colonne : le serveur l'écrira
        // avec son message `DEPOSIT`, que le pull rapportera (DEP-14). D'ici
        // là, la date de la dépense est ce que la fiche sait de plus proche —
        // c'est aussi le repli de la maquette.
        detail: when(expense.expenseDate, expense.recordedByName),
        done: true,
      ),
      _Milestone(
        // Refusée ou retirée s'écrivent **à la place** d'« Approuvée » : la
        // colonne dit ce qui a été décidé, pas ce qu'on espérait.
        label: expenseStatusLabel(
          l10n,
          aside ? status : ExpenseStatus.approved,
        ),
        icon: aside
            ? expenseStatusVisuals(status).icon
            : Icons.how_to_reg_outlined,
        detail: when(decided, expense.decidedByName),
        done: aside ? decided != null : reached >= 1,
        adverse: aside,
      ),
      _Milestone(
        label: expenseStatusLabel(l10n, ExpenseStatus.paid),
        icon: Icons.check_circle_outline,
        detail: when(paidOn, null),
        done: !aside && reached >= 2,
        // Une demande refusée ou retirée ne sera pas payée : le dire vaut
        // mieux que laisser lire « en attente », qui promettrait une suite.
        unreachable: aside,
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.expenseInsetRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.expenseInsetRadius),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < milestones.length; i++)
                Expanded(
                  child: _MilestoneCell(
                    milestone: milestones[i],
                    status: status,
                    divided: i > 0,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Milestone {
  final String label;
  final IconData icon;

  /// « 12 sept. · Mbala Thérèse », ou `null` tant que le jalon n'est pas
  /// franchi.
  final String? detail;
  final bool done;

  /// Le jalon porte une décision défavorable : il prend la teinte de l'état.
  final bool adverse;

  /// Le jalon ne sera jamais franchi.
  final bool unreachable;

  const _Milestone({
    required this.label,
    required this.icon,
    required this.detail,
    required this.done,
    this.adverse = false,
    this.unreachable = false,
  });
}

class _MilestoneCell extends StatelessWidget {
  final _Milestone milestone;
  final ExpenseStatus status;
  final bool divided;

  const _MilestoneCell({
    required this.milestone,
    required this.status,
    required this.divided,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adverse = expenseStatusVisuals(status);
    final done = milestone.done;
    // Trois lectures, trois familles : la décision défavorable emprunte la
    // teinte de l'état, le jalon franchi la famille du paiement, l'attente
    // l'encre muette. L'icône et le mot disent la même chose — la couleur ne
    // porte jamais seule.
    final ink = milestone.adverse
        ? adverse.color
        : done
        ? AppColors.feeStatusPaid
        : AppColors.textMuted;
    final background = milestone.adverse
        ? adverse.soft
        : done
        ? AppColors.feeStatusPaidSoft
        : AppColors.surfaceAlt;
    // Un jalon FRANCHI dont on ignore la date ne dit pas « en attente » : ce
    // serait se contredire dans la même cellule. Le cas est courant tant que
    // le pull ne rapporte pas les colonnes de décision (DEP-14) — et il le
    // restera pour toute ligne héritée de la V1, qui n'a jamais eu de
    // décideur.
    final detail =
        milestone.detail ??
        (milestone.unreachable
            ? l10n.expenseChainNeverPaid
            : milestone.done
            ? l10n.expenseNoValue
            : l10n.expenseChainAwaiting);
    return Opacity(
      opacity: milestone.unreachable
          ? AppDimensions.expenseChainDimmedOpacity
          : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.expenseChainPaddingV,
          horizontal: AppDimensions.expenseChainPaddingH,
        ),
        decoration: BoxDecoration(
          color: background,
          border: divided
              ? const Border(left: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  done ? milestone.icon : Icons.circle_outlined,
                  size: AppDimensions.expenseChainIconSize,
                  color: ink,
                ),
                const SizedBox(width: AppDimensions.expenseInlineGap),
                Expanded(
                  child: Text(
                    milestone.label,
                    style: AppTextStyles.bodyStrong.copyWith(
                      fontSize: 13,
                      color: ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingXS / 2),
            Text(
              detail,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
