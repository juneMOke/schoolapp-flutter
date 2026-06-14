import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/helpers/number_formatter_helper.dart';

/// Graphique en barres verticales générique pour une distribution par catégories.
///
/// [showValueLabels] affiche en permanence la valeur au-dessus de chaque barre
/// (via les tooltips épinglés de fl_chart, sans fond), à la couleur de la barre
/// — utile pour un rendu « étiquette par barre » sans interaction. Par défaut
/// off (rendu historique avec tooltip au survol sur fond sombre).
class CycleBarChart extends StatelessWidget {
  final List<BarChartItem> items;
  final Set<int> highlightedIndexes;
  final bool showValueLabels;
  final String Function(double value)? valueLabelFormatter;

  /// Couleur de l'étiquette de valeur par index (défaut : couleur de la barre).
  /// Permet ex. un libellé neutre sur les barres atténuées et coloré sur le pic.
  final Color Function(int index)? valueLabelColorBuilder;

  const CycleBarChart({
    super.key,
    required this.items,
    this.highlightedIndexes = const <int>{},
    this.showValueLabels = false,
    this.valueLabelFormatter,
    this.valueLabelColorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final topY = (maxVal * 1.25).ceilToDouble().clamp(10.0, double.infinity);
    final barWidth = (items.length > 4 ? 20.0 : 32.0);

    return SizedBox(
      height: AppDimensions.enrollmentStatsChartSectionHeight,
      child: BarChart(
        BarChartData(
          maxY: topY,
          barTouchData: BarTouchData(
            enabled: !showValueLabels,
            handleBuiltInTouches: !showValueLabels,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  showValueLabels ? Colors.transparent : AppColors.surfaceDark,
              tooltipRoundedRadius: 8,
              tooltipPadding: showValueLabels
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              fitInsideVertically: true,
              fitInsideHorizontally: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = items[group.x.toInt()];
                if (showValueLabels) {
                  // Étiquette permanente : valeur seule ; couleur dédiée si
                  // fournie (sinon couleur de la barre).
                  return BarTooltipItem(
                    (valueLabelFormatter ??
                        NumberFormatterHelper.formatYAxisLabel)(rod.toY),
                    AppTextStyles.caption.copyWith(
                      color:
                          valueLabelColorBuilder?.call(group.x.toInt()) ??
                          item.color,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTextStyles.tabularFigures,
                    ),
                  );
                }
                return BarTooltipItem(
                  '${item.label}\n${NumberFormatterHelper.formatYAxisLabel(rod.toY)}',
                  AppTextStyles.caption.copyWith(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (topY / 4).clamp(1, double.infinity),
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.enrollmentStatsChartGrid,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  NumberFormatterHelper.formatYAxisLabel(value),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= items.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: AppDimensions.spacingXS,
                    ),
                    child: Text(
                      items[idx].label,
                      style: AppTextStyles.caption.copyWith(
                        color: highlightedIndexes.contains(idx)
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: highlightedIndexes.contains(idx)
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < items.length; i++)
              BarChartGroupData(
                x: i,
                showingTooltipIndicators: showValueLabels
                    ? const [0]
                    : const [],
                barRods: [
                  BarChartRodData(
                    toY: items[i].value,
                    color: items[i].color,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.enrollmentStatsChartBorderRadius,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
