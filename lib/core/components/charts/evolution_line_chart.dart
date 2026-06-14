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
///
/// Par défaut le domaine vertical est dynamique (0 → max×1.2, grille /4 —
/// rendu historique). Pour un domaine FIXE (ex. un taux 70–100 %), fournir
/// [minY]/[maxY] (grille en 3 intervalles). [targetLine] ajoute une ligne
/// d'objectif horizontale pointillée et [leftLabelFormatter] personnalise les
/// libellés de l'axe Y (ex. suffixe « % »).
class EvolutionLineChart extends StatelessWidget {
  final List<LineChartPoint> points;
  final Color lineColor;
  final Color highlightColor;

  /// Bornes verticales fixes (optionnelles). Si nulles → domaine dynamique.
  final double? minY;
  final double? maxY;

  /// Ligne d'objectif horizontale pointillée (ex. 95). Nulle → aucune.
  final double? targetLine;
  final Color? targetLineColor;
  final String? targetLineLabel;

  /// Formateur des libellés de l'axe Y (défaut : entier via NumberFormatter).
  final String Function(double value)? leftLabelFormatter;

  const EvolutionLineChart({
    super.key,
    required this.points,
    required this.lineColor,
    required this.highlightColor,
    this.minY,
    this.maxY,
    this.targetLine,
    this.targetLineColor,
    this.targetLineLabel,
    this.leftLabelFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final spots = [
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];

    final dynamicMax = points
        .map((p) => p.value)
        .reduce((a, b) => a > b ? a : b);
    final bool hasFixedDomain = maxY != null;
    final double resolvedMinY = minY ?? 0;
    final double resolvedMaxY =
        maxY ?? (dynamicMax * 1.2).ceilToDouble().clamp(10.0, double.infinity);
    // Domaine fixe → 3 intervalles (ex. 70/80/90/100) ; sinon /4 (historique).
    final double gridInterval = hasFixedDomain
        ? ((resolvedMaxY - resolvedMinY) / 3).clamp(1.0, double.infinity)
        : (resolvedMaxY / 4).clamp(1.0, double.infinity);
    final Color targetColor = targetLineColor ?? AppColors.terreCuite;

    return SizedBox(
      height: AppDimensions.enrollmentStatsChartSectionHeight,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: resolvedMinY,
          maxY: resolvedMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: gridInterval,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.enrollmentStatsChartGrid,
              strokeWidth: 1,
            ),
          ),
          extraLinesData: targetLine == null
              ? const ExtraLinesData()
              : ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: targetLine!,
                      color: targetColor,
                      strokeWidth: 1.3,
                      dashArray: const [5, 4],
                      label: targetLineLabel == null
                          ? HorizontalLineLabel()
                          : HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: AppTextStyles.caption.copyWith(
                                color: targetColor,
                                fontWeight: FontWeight.w600,
                              ),
                              labelResolver: (_) => targetLineLabel!,
                            ),
                    ),
                  ],
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
                interval: hasFixedDomain ? gridInterval : null,
                getTitlesWidget: (value, meta) => Text(
                  (leftLabelFormatter ??
                      NumberFormatterHelper.formatYAxisLabel)(value),
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
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
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
