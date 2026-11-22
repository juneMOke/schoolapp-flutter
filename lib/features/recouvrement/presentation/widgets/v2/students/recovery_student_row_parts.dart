import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_texts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _tabular = [FontFeature.tabularFigures()];

/// Deux devises côte à côte, jamais additionnées.
const _mixedJoin = ' / ';

/// L'œil en bout de ligne (`RecEye`) : décoratif, la ligne entière est la
/// cible ; il nomme le geste au survol.
class RecoveryEye extends StatelessWidget {
  final String label;

  const RecoveryEye({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    excludeFromSemantics: true,
    child: Container(
      width: AppDimensions.recoveryStudentsEyeSize,
      height: AppDimensions.recoveryStudentsEyeSize,
      decoration: const BoxDecoration(
        color: AppColors.bleuArdoiseSoft,
        borderRadius: AppRadius.brMd,
      ),
      child: const Icon(
        Icons.visibility_outlined,
        size: AppSpacing.lg,
        color: AppColors.bleuArdoise,
      ),
    ),
  );
}

/// La situation (rien payé · partiel · soldé) et le verdict de la règle
/// (« En ordre » succès, « À relancer » erreur) — la couleur n'est jamais
/// seule (A18).
class RecoverySituationBadges extends StatelessWidget {
  final RecoveryStudentRow row;

  const RecoverySituationBadges({super.key, required this.row});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs + 2,
    runSpacing: AppSpacing.xs,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      RecoverySituationBadge(situation: row.situation),
      RecoveryVerdictBadge(inOrder: row.inOrder),
    ],
  );
}

class RecoverySituationBadge extends StatelessWidget {
  final StudentChargeStatus situation;

  const RecoverySituationBadge({super.key, required this.situation});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (situation) {
      StudentChargeStatus.due => StatusBadge.overdue(
        label: l10n.recoveryStudentsSituationNone,
        size: StatusBadgeSize.small,
      ),
      StudentChargeStatus.partial => StatusBadge.partial(
        label: l10n.recoveryStudentsSituationPartial,
        size: StatusBadgeSize.small,
      ),
      StudentChargeStatus.paid => StatusBadge.paid(
        label: l10n.recoveryStudentsSituationSettled,
        size: StatusBadgeSize.small,
      ),
    };
  }
}

/// « En ordre » / « À relancer » (`RecOrdrePill`), en badge plein.
class RecoveryVerdictBadge extends StatelessWidget {
  final bool inOrder;

  const RecoveryVerdictBadge({super.key, required this.inOrder});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StatusBadge(
      icon: inOrder ? Icons.check : Icons.close,
      label: inOrder
          ? l10n.recoveryStudentsInOrder
          : l10n.recoveryStudentsToChase,
      color: inOrder ? AppColors.success : AppColors.error,
      size: StatusBadgeSize.small,
      style: StatusBadgeStyle.filled,
    );
  }
}

/// Un montant par devise, une ligne chacune, alignés à droite ; jamais
/// additionnés ni coupés.
class RecoveryMoneyLines extends StatelessWidget {
  final List<Money> amounts;
  final List<String> currencies;
  final Color? tone;

  const RecoveryMoneyLines({
    super.key,
    required this.amounts,
    required this.currencies,
    this.tone,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final line in recoveryAmountLines(amounts, currencies))
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            line,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: tone ?? AppColors.textPrimary,
              fontFeatures: _tabular,
            ),
          ),
        ),
    ],
  );
}

/// « payé {montant} » sous le reste (disposition repliée).
class RecoveryPaidUnder extends StatelessWidget {
  final List<Money> amounts;
  final List<String> currencies;

  const RecoveryPaidUnder({
    super.key,
    required this.amounts,
    required this.currencies,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in recoveryAmountLines(amounts, currencies))
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              l10n.recoveryStudentsPaidUnder(line),
              maxLines: 1,
              softWrap: false,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
                fontFeatures: _tabular,
              ),
            ),
          ),
      ],
    );
  }
}

/// La seconde ligne d'une carte (sous 600) : le statut, puis « Payé … ·
/// Reste … » — une paire par devise en mixte.
class RecoveryCardAmounts extends StatelessWidget {
  final RecoveryStudentRow row;
  final List<String> currencies;
  final Color outstandingTone;

  const RecoveryCardAmounts({
    super.key,
    required this.row,
    required this.currencies,
    required this.outstandingTone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = AppTypography.labelSmall.copyWith(
      color: AppColors.textSecondary,
      fontFeatures: _tabular,
    );
    final strong = muted.copyWith(fontWeight: FontWeight.w700);
    return Wrap(
      spacing: AppSpacing.sm + 2,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RecoveryVerdictBadge(inOrder: row.inOrder),
        Text.rich(
          TextSpan(
            style: muted,
            children: [
              TextSpan(text: '${l10n.recoveryStudentsCardPaid} '),
              TextSpan(
                text: recoveryAmountLines(
                  row.paid,
                  currencies,
                ).join(_mixedJoin),
                style: strong.copyWith(color: AppColors.textPrimary),
              ),
              const TextSpan(text: ' · '),
              TextSpan(text: '${l10n.recoveryStudentsCardOutstanding} '),
              TextSpan(
                text: recoveryAmountLines(
                  row.outstanding,
                  currencies,
                ).join(_mixedJoin),
                style: strong.copyWith(color: outstandingTone),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
