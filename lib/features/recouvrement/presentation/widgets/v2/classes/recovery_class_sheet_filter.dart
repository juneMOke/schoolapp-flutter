import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_v2_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le nom de fil d'une situation pour la fiche de classe (`situation=…`).
String? recoverySituationWire(StudentChargeStatus? status) => switch (status) {
  null => null,
  StudentChargeStatus.due => 'NO_PAYMENT',
  StudentChargeStatus.partial => 'PARTIAL',
  StudentChargeStatus.paid => 'SETTLED',
};

/// Le filtre de la fiche de classe (O2) : Tous · Rien payé · Partiel · Soldé,
/// chacun avec son compteur. Un seul choix (rôle radio) ; `null` = Tous.
class RecoveryClassSheetFilter extends StatelessWidget {
  final StudentChargeStatus? value;
  final RecoverySituationCounts counts;
  final ValueChanged<StudentChargeStatus?> onChanged;

  const RecoveryClassSheetFilter({
    super.key,
    required this.value,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = <(StudentChargeStatus?, String, int)>[
      (null, l10n.recoveryClassSheetAll, counts.total),
      (
        StudentChargeStatus.due,
        l10n.recoveryClassSheetNoPayment,
        counts.noPayment,
      ),
      (
        StudentChargeStatus.partial,
        l10n.recoveryClassSheetPartial,
        counts.partial,
      ),
      (
        StudentChargeStatus.paid,
        l10n.recoveryClassSheetSettled,
        counts.settled,
      ),
    ];
    return Semantics(
      label: l10n.recoveryClassSheetFilterLabel,
      container: true,
      child: Wrap(
        spacing: AppSpacing.sm - 2,
        runSpacing: AppSpacing.sm - 2,
        children: [
          for (final (status, label, count) in options)
            _Chip(
              label: label,
              count: count,
              status: status,
              selected: status == value,
              onTap: () => onChanged(status),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final StudentChargeStatus? status;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.count,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (ink, soft) = RecouvrementV2Tones.situation(status);
    final text = status == StudentChargeStatus.partial
        ? AppColors.feeStatusPartialInk
        : ink;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: EteeloActivatable(
        onActivate: onTap,
        semanticLabel: l10n.recoveryClassSheetFilterA11y(label, count),
        builder: (context, highlight) => ExcludeSemantics(
          // 36 à l'œil, 48 au doigt : la zone d'appui déborde la pastille.
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppDimensions.recoveryClassFilterHeight,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: selected ? soft : AppColors.surfaceRaised,
                  borderRadius: AppRadius.brPill,
                  border: Border.all(
                    color: selected || highlight.focused
                        ? ink
                        : AppColors.border,
                    width: selected || highlight.focused ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTypography.labelLarge.copyWith(
                        color: selected ? text : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm - 2),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.lg + AppSpacing.xs,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm - 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.surfaceRaised
                            : AppColors.surfaceAlt,
                        borderRadius: AppRadius.brPill,
                      ),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected ? text : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
