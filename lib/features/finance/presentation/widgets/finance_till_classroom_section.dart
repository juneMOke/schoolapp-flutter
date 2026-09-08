import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_bar_rows.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Où la caisse s'alimente** — les classes qui ont le plus versé.
///
/// Un **palmarès**, jamais un total : le serveur coupe à huit lignes et il
/// n'existe aucune ligne « autres ». Sur une fenêtre courte, la carte répond
/// surtout à « quelle classe a payé aujourd'hui ».
///
/// ## Une seule teinte, et c'est un choix
///
/// La carte est un **classement**, pas une taxonomie. Le cycle a été retiré : il
/// aurait dû être doublé du texte — une couleur ne porte jamais seule une
/// information — et en toutes lettres il répète ce que le nom de la classe dit
/// déjà (« 1ère humanités · Secondaire »).
///
/// ⚠️ **Réserve à connaître** : ça ne tient que parce que les classes de ce parc
/// se nomment d'après leur cycle. Une école qui nommerait ses classes « A1 »,
/// « B2 » rendrait le cycle informatif, et il faudrait rouvrir la question — en
/// sachant que le serveur devrait traverser deux ports pour le reconstituer.
class FinanceTillClassroomSection extends StatelessWidget {
  final TillCurrencyBlock block;

  const FinanceTillClassroomSection({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = block.byClassroom;

    String money(int cents) =>
        MoneyFormat.format(Money.parse(cents, block.currency));

    return FinanceStatsChartCard(
      title: l10n.financeTillClassroomHeading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le sous-titre annonce **le nombre réellement affiché**, jamais un
          // « top 8 » figé : une école de cinq classes en montre cinq.
          Text(
            l10n.financeTillClassroomHint(rows.length),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          if (rows.isEmpty)
            FinanceStatsEmptyState(
              message: l10n.financeTillClassroomEmpty,
              hint: l10n.financeTillClassroomEmptyHint,
              semanticLabel: l10n.financeStatsEmptyA11yLabel,
            )
          else
            EteeloBarRows(
              rows: [
                for (final row in rows)
                  EteeloBarRow(
                    label: row.name,
                    value: row.amount,
                    valueLabel: money(row.amount),
                    // Une teinte unique : la couleur repère la carte, elle ne
                    // classe pas.
                    color: AppColors.bleuArdoise,
                    semanticsLabel: l10n.financeTillClassroomRowA11yLabel(
                      row.name,
                      money(row.amount),
                    ),
                  ),
              ],
            ),
          // **Sans cette mention, le classement passe pour un bug.** La somme
          // des lignes ne retombe pas sur le total de la caisse, et le lecteur
          // cherche l'erreur — alors qu'une vente boutique ne désigne ni élève
          // ni classe, et n'a donc aucune ligne où figurer.
          if (block.hasUnassigned) ...[
            const SizedBox(height: AppDimensions.spacingM),
            _UnassignedNote(amount: money(block.unassignedAmount), l10n: l10n),
          ],
        ],
      ),
    );
  }
}

/// Ce qui est entré sans désigner de classe.
class _UnassignedNote extends StatelessWidget {
  final String amount;
  final AppLocalizations l10n;

  const _UnassignedNote({required this.amount, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.financeTillClassroomUnassigned(amount),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
