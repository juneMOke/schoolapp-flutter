import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/helpers/number_formatter_helper.dart';

/// Graphique en barres verticales générique pour une distribution par catégories.
class CycleBarChart extends StatelessWidget {
  final List<BarChartItem> items;
  final Set<int> highlightedIndexes;

  const CycleBarChart({
    super.key,
    required this.items,
    this.highlightedIndexes = const <int>{},
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
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceDark,
              tooltipRoundedRadius: 8,
               getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 final item = items[group.x.toInt()];
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
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  NumberFormatterHelper.formatYAxisLabel(value),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
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
                    padding: const EdgeInsets.only(top: AppDimensions.spacingXS),
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