import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_chart_tones.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_dashboard_figures.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_month_columns.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Net à payer : payé et non payé » (spec TB 1) : le mois affiché, puis
/// chaque mois tenu — toucher une colonne ouvre ce mois.
class PayrollDashboardPaidCard extends StatelessWidget {
  final PayrollNetProgress progress;
  final bool validated;
  final String currency;
  final List<PayrollMonthColumn> columns;
  final String month;
  final ValueChanged<String> onOpenMonth;
  final VoidCallback onPrepare;

  const PayrollDashboardPaidCard({
    super.key,
    required this.progress,
    required this.validated,
    required this.currency,
    required this.columns,
    required this.month,
    required this.onOpenMonth,
    required this.onPrepare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, currency);
    final total = progress.totalInCents;
    final paidPercent = total == 0
        ? 0
        : (progress.paidInCents * 100 / total).round();
    final segments = [
      (l10n.payrollDashPaid, progress.paidInCents, PayrollChartTones.paid),
      (
        l10n.payrollDashDeferred,
        progress.deferredInCents,
        PayrollChartTones.deferred,
      ),
      (
        l10n.payrollDashUnpaid,
        progress.unpaidInCents,
        PayrollChartTones.unpaid,
      ),
    ];
    return PayrollDashboardCard(
      title: l10n.payrollDashPaidTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (validated) ...[
            EteeloSplitBar(
              semanticsLabel: [
                for (final segment in segments)
                  '${segment.$1} ${money(segment.$2)}',
              ].join(', '),
              segments: [
                for (final segment in segments)
                  EteeloSplitBarSegment(
                    label: segment.$1,
                    valueLabel: money(segment.$2),
                    value: segment.$2,
                    color: segment.$3,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                l10n.payrollDashPaidSummary(paidPercent, progress.settledCount),
                l10n.payrollDashUnpaidSummary(
                  progress.partialCount,
                  progress.unpaidCount,
                ),
              ].join(' · '),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.payrollDashNothingBeforeValidation),
                EteeloButton.ghost(
                  label: l10n.payrollDashPrepare,
                  icon: Icons.arrow_forward,
                  onPressed: onPrepare,
                  fullWidth: false,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.payrollDashByMonth, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          PayrollMonthColumns(
            columns: columns,
            focusedMonth: month,
            currency: currency,
            onTap: onOpenMonth,
          ),
        ],
      ),
    );
  }
}
