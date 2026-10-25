import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_dashboard_figures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Prévu et réel du mois » (spec TB 1) : combien la paie devait coûter,
/// combien il faut réellement payer, et ce qui sépare les deux.
class PayrollDashboardForecastCard extends StatelessWidget {
  final PayrollMonthView view;
  final PayrollForecast forecast;
  final String currency;

  /// Arriérés marqués « en priorité » à verser avec ce mois, ou 0.
  final int prioritizedArrearsInCents;

  const PayrollDashboardForecastCard({
    super.key,
    required this.view,
    required this.forecast,
    required this.currency,
    this.prioritizedArrearsInCents = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, currency);
    final gross = forecast.grossInCents;
    final saved = forecast.savedInCents;
    final percent = gross == 0 ? 0 : (saved * 100 / gross).round();
    final validatedAt = view.header?.validatedAt;
    final segments = [
      (l10n.payrollDashNet, forecast.netInCents, AppColors.payrollChartNet),
      (
        l10n.payrollDashAbsence,
        forecast.absenceInCents,
        AppColors.payrollChartAbsence,
      ),
      (
        l10n.payrollDashAdvances,
        forecast.advancesInCents,
        AppColors.payrollChartAdvances,
      ),
      (
        l10n.payrollDashLegal,
        forecast.legalInCents,
        AppColors.payrollChartLegal,
      ),
      (
        l10n.payrollDashChildcare,
        forecast.childcareInCents,
        AppColors.payrollChartChildcare,
      ),
      (l10n.payrollDashOther, forecast.otherInCents, AppColors.textMuted),
    ].where((segment) => segment.$2 > 0).toList();
    return PayrollDashboardCard(
      title: l10n.payrollDashForecastTitle,
      subtitle: view.header?.status == PayrollStatus.validated
          ? l10n.payrollDashValidatedOn(
              validatedAt == null
                  ? '—'
                  : PayrollLabels.day(context, validatedAt),
            )
          : l10n.payrollDashDraftSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _Figure(
                label: l10n.payrollDashPlanned,
                value: money(gross),
                color: AppColors.textPrimary,
              ),
              _Figure(
                label: l10n.payrollDashActual,
                value: money(forecast.netInCents),
                color: AppColors.payrollChartNet,
                note: saved > 0
                    ? l10n.payrollDashLessThanPlanned(money(saved), percent)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
          if (prioritizedArrearsInCents > 0) ...[
            const SizedBox(height: AppSpacing.md),
            EteeloNotice.warning(
              l10n.payrollDashArrearsCarried(
                money(prioritizedArrearsInCents),
                money(forecast.netInCents + prioritizedArrearsInCents),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? note;

  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    this.note,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      Text(value, style: AppTypography.money.copyWith(color: color)),
      if (note case final note?)
        Text(
          note,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.payrollChartNet,
          ),
        ),
    ],
  );
}
