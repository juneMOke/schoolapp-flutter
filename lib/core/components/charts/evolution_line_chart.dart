import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/line_chart_point.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/helpers/number_formatter_helper.dart';

/// Graphique en ligne générique pour visualiser une évolution dans le temps.
///
/// [points] : données ordonnées (abscisse = index de la liste).
/// [lineColor] : couleur principale de la ligne.
/// [highlightColor] : couleur du point mis en évidence.
class EvolutionLineChart extends StatelessWidget {
  final List<LineChartPoint> points;
  final Color lineColor;
  final Color highlightColor;

  const EvolutionLineChart({
    super.key,
    required this.points,
    required this.lineColor,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final spots = [
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];

    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final topY = (maxY * 1.2).ceilToDouble().clamp(10.0, double.infinity);

    return SizedBox(
      height: AppDimensions.enrollmentStatsChartSectionHeight,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: topY,
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
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length)
                    return const SizedBox.shrink();
                  return Text(
                    points[idx].label,
                    style: AppTextStyles.caption.copyWith(
                      color: points[idx].isHighlighted
                          ? highlightColor
                          : AppColors.textSecondary,
                      fontWeight: points[idx].isHighlighted
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) =>
                    points[spot.x.toInt()].isHighlighted,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 5,
                  color: highlightColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.18),
                    lineColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
