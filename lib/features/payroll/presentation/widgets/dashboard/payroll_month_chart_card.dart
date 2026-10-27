import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_segment.dart';
import 'package:school_app_flutter/core/components/charts/chart_legend.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_chart_tones.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_dashboard_months.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Mois par mois » : le net de chaque mois de la fenêtre servie, empilé
/// payé / reporté / non payé / pas encore versé, dans la devise affichée. Le
/// mois affiché est cerné ; toucher une barre l'ouvre — la frise de l'en-tête
/// reste l'autre chemin, atteignable au lecteur d'écran.
class PayrollMonthChartCard extends StatelessWidget {
  final PayrollDashboard dashboard;
  final String currency;
  final ValueChanged<String> onOpenMonth;

  const PayrollMonthChartCard({
    super.key,
    required this.dashboard,
    required this.currency,
    required this.onOpenMonth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final legend = [
      BarChartSegment(
        label: l10n.payrollDashPaid,
        value: 0,
        color: PayrollChartTones.paid,
      ),
      BarChartSegment(
        label: l10n.payrollDashDeferred,
        value: 0,
        color: PayrollChartTones.deferred,
      ),
      BarChartSegment(
        label: l10n.payrollDashUnpaid,
        value: 0,
        color: PayrollChartTones.unpaid,
      ),
      BarChartSegment(
        label: l10n.payrollDashNotYet,
        value: 0,
        color: PayrollChartTones.notYet,
      ),
    ];
    final byMonth = {for (final m in dashboard.months) m.month: m};
    final start = PayrollMonth.add(
      dashboard.month,
      1 - PayrollDashboardMonths.window,
    );
    final months = [
      for (var i = 0; i < PayrollDashboardMonths.window; i++)
        PayrollMonth.add(start, i),
    ];
    // Les barres se dessinent en unités de la devise, pas en centimes : l'axe
    // et l'échelle se lisent alors comme des montants.
    double units(int cents) => cents / 100;
    final items = [
      for (final month in months)
        BarChartItem.stacked(
          label: _label(l10n, month),
          color: PayrollChartTones.notYet,
          segments: [
            for (final (index, part) in legend.indexed)
              BarChartSegment(
                label: part.label,
                color: part.color,
                value: units(switch (index) {
                  0 => byMonth[month]?.byCurrency[currency]?.paidInCents ?? 0,
                  1 =>
                    byMonth[month]?.byCurrency[currency]?.deferredInCents ?? 0,
                  2 => byMonth[month]?.byCurrency[currency]?.unpaidInCents ?? 0,
                  _ => byMonth[month]?.byCurrency[currency]?.notYetInCents ?? 0,
                }),
              ),
          ],
        ),
    ];
    return EteeloStatsCard(
      title: l10n.payrollDashByMonth,
      subtitle: l10n.payrollDashByMonthSubtitle(currency),
      icon: Icons.bar_chart_rounded,
      tone: DashboardSense.attendu,
      toneStrength: DashboardTones.forceDe(DashboardSense.attendu),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CycleBarChart(
            items: items,
            highlightedIndexes: {months.indexOf(dashboard.month)},
            highlightBorderColor: PayrollTone.current.color,
            verticalBottomLabels: true,
            valueLabelFormatter: (value) =>
                PayrollLabels.money((value * 100).round(), currency),
            onBarTap: (index) => onOpenMonth(months[index]),
          ),
          const SizedBox(height: AppSpacing.sm),
          ChartLegend(entries: legend),
        ],
      ),
    );
  }

  /// « oct. 26 » : l'année courte, deux octobres ne se confondent pas.
  static String _label(AppLocalizations l10n, String month) =>
      '${PayrollLabels.monthShort(l10n, month)} ${month.substring(2, 4)}';
}
