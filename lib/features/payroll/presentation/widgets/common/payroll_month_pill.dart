import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un mois de la frise : « oct. » sur « 2026 », au voile de son statut, un
/// point de sa teinte. Le mois affiché est cerné à la marque. Un mois sans
/// paie reste blanc, bordé.
class PayrollMonthPill extends StatelessWidget {
  /// `YYYY-MM`.
  final String month;

  /// `null` : aucune paie ce mois-là.
  final PayrollPhase? phase;
  final bool selected;
  final VoidCallback onTap;

  const PayrollMonthPill({
    super.key,
    required this.month,
    required this.phase,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phase = this.phase;
    final tone = phase == null ? null : PayrollTone.of(phase);
    final status = phase == null
        ? l10n.payrollMonthNoPayroll
        : PayrollLabels.phase(l10n, phase);
    final ring = PayrollTone.current.color;
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.payrollMonthPillA11y(
        PayrollLabels.month(context, month),
        status,
      ),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: tone?.soft ?? AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(
            color: selected ? ring : (tone?.color ?? AppColors.border),
            width: selected
                ? AppDimensions.chartHighlightBorderWidth
                : AppDimensions.tileBorderWidth,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tone != null) ...[
                        Container(
                          width: AppSpacing.sm,
                          height: AppSpacing.sm,
                          decoration: BoxDecoration(
                            color: tone.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          PayrollLabels.monthShort(l10n, month),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(
                            color: tone?.ink ?? AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    month.substring(0, 4),
                    maxLines: 1,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
