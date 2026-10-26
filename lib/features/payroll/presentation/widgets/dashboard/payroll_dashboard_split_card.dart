import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_chart_tones.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Deux barres partagées : ce qui sépare le brut du net (les cinq retenues
/// réellement prises), puis où en est le net (payé, reporté, non payé — ou,
/// avant validation, pas encore versé).
class PayrollDashboardSplitCard extends StatelessWidget {
  final PayrollDashboard dashboard;
  final PayrollDashboardCurrency section;

  const PayrollDashboardSplitCard({
    super.key,
    required this.dashboard,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, section.currency);
    final forecast = section.forecast;
    final progress = section.progress;
    final deductions = [
      (l10n.payrollDashNet, forecast.netInCents, PayrollChartTones.net),
      (
        l10n.payrollDashAbsence,
        forecast.absenceInCents,
        PayrollChartTones.absence,
      ),
      (
        l10n.payrollDashAdvances,
        forecast.advancesInCents,
        PayrollChartTones.advances,
      ),
      (l10n.payrollDashLegal, forecast.legalInCents, PayrollChartTones.legal),
      (
        l10n.payrollDashChildcare,
        forecast.childcareInCents,
        PayrollChartTones.childcare,
      ),
    ];
    final net = progress == null
        ? const <(String, int, Color)>[]
        : [
            (
              l10n.payrollDashPaid,
              progress.paidInCents,
              PayrollChartTones.paid,
            ),
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
            (
              l10n.payrollDashNotYet,
              progress.notYetInCents,
              PayrollChartTones.notYet,
            ),
          ];
    return EteeloStatsCard(
      title: l10n.payrollDashSplitTitle,
      subtitle: dashboard.isValidated
          ? l10n.payrollDashValidatedOn(
              dashboard.validatedAt == null
                  ? l10n.payrollNoValue
                  : PayrollLabels.day(context, dashboard.validatedAt!),
            )
          : l10n.payrollDashDraftSubtitle,
      icon: Icons.stacked_bar_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bar(l10n.payrollDashForecastTitle, deductions, money),
          if (net.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _bar(l10n.payrollDashPaidTitle, net, money),
            if (progress != null && dashboard.isValidated) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.payrollDashUnpaidSummary(
                  progress.partialCount,
                  progress.unpaidCount,
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
          if (section.priorityArrearsInCents > 0) ...[
            const SizedBox(height: AppSpacing.md),
            EteeloNotice.warning(
              l10n.payrollDashArrearsCarried(
                money(section.priorityArrearsInCents),
                money(forecast.netInCents + section.priorityArrearsInCents),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _bar(
    String title,
    List<(String, int, Color)> parts,
    String Function(int) money,
  ) {
    final shown = [
      for (final part in parts)
        if (part.$2 > 0) part,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        EteeloSplitBar(
          semanticsLabel: [
            title,
            for (final part in shown) '${part.$1} ${money(part.$2)}',
          ].join(', '),
          segments: [
            for (final part in shown)
              EteeloSplitBarSegment(
                label: part.$1,
                valueLabel: money(part.$2),
                value: part.$2,
                color: part.$3,
              ),
          ],
        ),
      ],
    );
  }
}
