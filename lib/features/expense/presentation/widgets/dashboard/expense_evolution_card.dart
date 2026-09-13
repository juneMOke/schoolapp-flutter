import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_series_builder.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_dashboard_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_section_note.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_section_head.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'évolution des dépenses (spec §11, règle 6) : une barre par jour, ou par
/// mois sur l'année scolaire. Terre cuite, la couleur du décaissement.
///
/// Chaque barre est une **lecture** en dollars au taux du jour, et la note le
/// dit en nommant le taux. Sans taux, des barres qui mêleraient francs et
/// dollars n'auraient pas d'unité : le graphique se tait et dit pourquoi
/// (A5). Une période tout en une devise se trace dans cette devise.
class ExpenseEvolutionCard extends StatelessWidget {
  final ExpenseDashboardView view;
  final ExpenseGranularity granularity;
  final String periodDetail;
  final ExchangeRate? rate;

  const ExpenseEvolutionCard({
    super.key,
    required this.view,
    required this.granularity,
    required this.periodDetail,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = view.series;
    final readable = points.every((p) => p.totals.usdCents != null);
    final currencies = {for (final p in points) ...p.totals.bag.currencies};
    final single = currencies.length == 1 ? currencies.first : null;
    final drawable = readable || currencies.length <= 1;

    return ExpenseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpenseSectionHead(
            icon: Icons.trending_up,
            title: l10n.expenseEvolutionTitle,
            subtitle: switch (granularity) {
              ExpenseGranularity.schoolYear => l10n.expenseEvolutionByMonth(
                periodDetail,
              ),
              ExpenseGranularity.month => l10n.expenseEvolutionByDayOf(
                periodDetail,
              ),
              ExpenseGranularity.week => l10n.expenseEvolutionByDay(
                periodDetail,
              ),
              ExpenseGranularity.day => l10n.expenseEvolutionLastSevenDays(
                periodDetail,
              ),
            },
          ),
          if (!drawable)
            ExpenseSectionNote(text: l10n.expenseEvolutionNoRate)
          else
            SizedBox(
              height: AppDimensions.expenseChartHeight,
              child: Semantics(
                container: true,
                label: l10n.expenseEvolutionA11y(periodDetail),
                child: CycleBarChart(
                  items: [
                    for (final point in points)
                      BarChartItem(
                        label: _label(l10n, point.bucket),
                        value: _value(point, readable, single) / 100,
                        color: point.bucket.highlighted
                            ? AppColors.terreCuite
                            : AppColors.terreCuiteMuted,
                      ),
                  ],
                  highlightedIndexes: {
                    for (var i = 0; i < points.length; i++)
                      if (points[i].bucket.highlighted) i,
                  },
                  showValueLabels: points.length <= 10,
                  labelHighlightedBars: true,
                  showLeftAxis: false,
                  gridDivisions: 2,
                  verticalBottomLabels: points.length > 16,
                  valueLabelFormatter: (value) => readable || single == null
                      ? ExpenseMoneyText.usdCompact((value * 100).round())
                      : MoneyFormat.compact(
                          Money((value * 100).round(), single),
                        ),
                ),
              ),
            ),
          if (rate != null && readable)
            ExpenseSectionNote(
              text: l10n.expenseEvolutionNoteRate(ExpenseMoneyText.rate(rate!)),
            ),
        ],
      ),
    );
  }

  static int _value(ExpenseSeriesPoint point, bool readable, String? single) {
    if (point.bucket.future) return 0;
    if (readable) return point.totals.usdCents ?? 0;
    return single == null
        ? 0
        : point.totals.bag.amountIn(single)?.amountInCents ?? 0;
  }

  String _label(AppLocalizations l10n, ExpenseSeriesBucket bucket) {
    final start = bucket.start;
    if (bucket.unit == ExpenseSeriesUnit.month) {
      return l10n.expenseMonthShort(start.month.toString());
    }
    return granularity == ExpenseGranularity.month
        ? '${start.day}'
        : l10n.expenseWeekdayShort(start.weekday.toString());
  }
}
