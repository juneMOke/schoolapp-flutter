import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_v2_tones.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_ranking_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La liste colorée de la fiche de classe (O2) : soldé sur fond vert, partiel
/// et rien payé sur fond rouge pâle, le liseré gauche dit la situation (vert,
/// ocre, rouge). Le mot accompagne toujours la couleur (badge de situation).
///
/// Toute la ligne ouvre la fiche de l'élève (O4) ; l'œil n'en est que le
/// repère.
class RecoveryClassStudentList extends StatelessWidget {
  final List<RecoveryStudentRow> rows;
  final ValueChanged<RecoveryStudentRow> onStudentTapped;

  const RecoveryClassStudentList({
    super.key,
    required this.rows,
    required this.onStudentTapped,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.border),
    ),
    child: ClipRRect(
      borderRadius: AppRadius.brMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _StudentLine(row: row, onTap: () => onStudentTapped(row)),
          ],
        ],
      ),
    ),
  );
}

/// Les montants d'une liste par devise — jamais additionnés : « 10 $ ·
/// 5 000 FC ».
String recoveryAmounts(List<Money> amounts) =>
    amounts.map(MoneyFormat.format).join(' · ');

class _StudentLine extends StatelessWidget {
  final RecoveryStudentRow row;
  final VoidCallback onTap;

  const _StudentLine({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settled = row.situation == StudentChargeStatus.paid;
    final stripe = switch (row.situation) {
      StudentChargeStatus.paid => AppColors.feeStatusPaid,
      StudentChargeStatus.partial => AppColors.orDoux,
      StudentChargeStatus.due => AppColors.feeStatusDue,
    };
    final detail = [
      ?_matricule(row.matriculationNumber),
      l10n.recoveryClassSheetPaidOf(
        recoveryAmounts(row.paid),
        recoveryAmounts(row.due),
      ),
      if (!settled)
        l10n.recoveryClassesOutstanding(recoveryAmounts(row.outstanding)),
    ].join(' · ');
    final badge = _badge(l10n);
    return EteeloActivatable(
      onActivate: onTap,
      semanticLabel: [
        l10n.recoveryClassSheetViewStudent(row.displayName),
        badge.label,
        detail,
      ].join(' · '),
      builder: (context, highlight) => ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppDimensions.recoverySpace9,
            AppSpacing.md,
            AppDimensions.recoverySpace9,
          ),
          decoration: BoxDecoration(
            color: settled
                ? AppColors.feeStatusPaidSoft
                : AppColors.feeStatusDueSoft,
            border: BorderDirectional(
              start: BorderSide(
                color: stripe,
                width: AppDimensions.recoveryClassStudentStripe,
              ),
            ),
          ),
          foregroundDecoration: highlight.focused
              ? BoxDecoration(
                  border: Border.all(
                    color: AppColors.bleuArdoise,
                    width: AppDimensions.focusRingWidth,
                  ),
                )
              : null,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      detail,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMutedAa,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.recoverySpace10),
              badge,
              const SizedBox(width: AppDimensions.recoverySpace10),
              const RecoveryEye(),
            ],
          ),
        ),
      ),
    );
  }

  static String? _matricule(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  StatusBadge _badge(AppLocalizations l10n) {
    final (ink, _) = RecouvrementV2Tones.situation(row.situation);
    final (icon, label) = switch (row.situation) {
      StudentChargeStatus.paid => (
        Icons.check_circle,
        l10n.recoveryClassSheetSettled,
      ),
      StudentChargeStatus.partial => (
        Icons.timelapse,
        l10n.recoveryClassSheetPartial,
      ),
      StudentChargeStatus.due => (
        Icons.cancel_outlined,
        l10n.recoveryClassSheetNoPayment,
      ),
    };
    return StatusBadge(
      icon: icon,
      label: label,
      color: ink,
      size: StatusBadgeSize.small,
    );
  }
}
