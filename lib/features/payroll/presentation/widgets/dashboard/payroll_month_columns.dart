import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_dashboard_figures.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un mois tenu de la série.
class PayrollMonthColumn {
  /// `YYYY-MM`.
  final String month;
  final PayrollNetProgress progress;

  const PayrollMonthColumn(this.month, this.progress);
}

/// « Mois par mois » (spec TB 1) : une colonne par mois tenu, empilée payé /
/// reporté / non payé / pas encore versé, à l'échelle du mois le plus lourd.
/// Le mois affiché est cerné ; toucher une colonne l'ouvre. La légende écrit
/// chaque teinte, et chaque colonne dit ses montants au lecteur d'écran.
class PayrollMonthColumns extends StatelessWidget {
  /// Du plus ancien au plus récent.
  final List<PayrollMonthColumn> columns;
  final String focusedMonth;
  final String currency;
  final ValueChanged<String> onTap;

  const PayrollMonthColumns({
    super.key,
    required this.columns,
    required this.focusedMonth,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = columns.fold(
      0,
      (max, column) => column.progress.totalInCents > max
          ? column.progress.totalInCents
          : max,
    );
    final legend = [
      (l10n.payrollDashPaid, AppColors.payrollChartPaid),
      (l10n.payrollDashDeferred, AppColors.payrollChartDeferred),
      (l10n.payrollDashUnpaid, AppColors.payrollChartUnpaid),
      (l10n.payrollDashNotYet, AppColors.payrollChartNotYet),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final column in columns)
                _Column(
                  column: column,
                  scale: scale,
                  focused: column.month == focusedMonth,
                  label: l10n.hrPresenceMonthShort(
                    column.month.substring(5).replaceFirst(RegExp('^0'), ''),
                  ),
                  semantics: l10n.payrollDashColumnA11y(
                    PayrollLabels.month(context, column.month),
                    PayrollLabels.money(column.progress.paidInCents, currency),
                    PayrollLabels.money(
                      column.progress.totalInCents -
                          column.progress.paidInCents,
                      currency,
                    ),
                  ),
                  onTap: () => onTap(column.month),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final (label, color) in legend)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSpacing.sm,
                    height: AppSpacing.sm,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: AppRadius.brSm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(label, style: AppTypography.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  final PayrollMonthColumn column;
  final int scale;
  final bool focused;
  final String label;
  final String semantics;
  final VoidCallback onTap;

  const _Column({
    required this.column,
    required this.scale,
    required this.focused,
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = column.progress;
    final parts = [
      (progress.notYetInCents, AppColors.payrollChartNotYet),
      (progress.unpaidInCents, AppColors.payrollChartUnpaid),
      (progress.deferredInCents, AppColors.payrollChartDeferred),
      (progress.paidInCents, AppColors.payrollChartPaid),
    ];
    const height = AppDimensions.payrollDashColumnsHeight;
    return Semantics(
      button: true,
      selected: focused,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Container(
          width: AppDimensions.payrollDashColumnWidth,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: focused
                  ? AppColors.payrollChartFocus
                  : AppColors.payrollChartNoFocus,
              width: AppDimensions.payrollDashFocusBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: height,
                width: AppDimensions.payrollDashColumnBarWidth,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final (cents, color) in parts)
                      if (cents > 0 && scale > 0)
                        Container(height: height * cents / scale, color: color),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: AppTypography.labelSmall.copyWith(
                  color: focused ? AppColors.payrollChartFocus : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
