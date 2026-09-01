import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/chart_entrance.dart';
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
///
/// [verticalBottomLabels] pivote de 90° le libellé sous chaque barre. À activer
/// quand les catégories sont nombreuses ou leurs libellés longs : à l'horizontale
/// ils se chevauchent ou se replient sur deux lignes. La hauteur réservée sous
/// l'axe est alors calculée sur le libellé le plus long — fl_chart contraint la
/// hauteur du titre, un libellé plus large que la réserve serait replié.
class CycleBarChart extends StatelessWidget {
  final List<BarChartItem> items;
  final Set<int> highlightedIndexes;
  final bool showValueLabels;
  final bool verticalBottomLabels;
  final String Function(double value)? valueLabelFormatter;

  /// Couleur de l'étiquette de valeur par index (défaut : couleur de la barre).
  /// Permet ex. un libellé neutre sur les barres atténuées et coloré sur le pic.
  final Color Function(int index)? valueLabelColorBuilder;

  const CycleBarChart({
    super.key,
    required this.items,
    this.highlightedIndexes = const <int>{},
    this.showValueLabels = false,
    this.verticalBottomLabels = false,
    this.valueLabelFormatter,
    this.valueLabelColorBuilder,
  });

  /// Style du libellé sous l'axe pour la barre [index].
  /// Sert aussi bien au rendu qu'à la mesure de la hauteur à réserver.
  TextStyle _bottomLabelStyle(int index) {
    final highlighted = highlightedIndexes.contains(index);
    return AppTextStyles.caption.copyWith(
      color: highlighted ? AppColors.textPrimary : AppColors.textSecondary,
      fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
    );
  }

  /// Hauteur à réserver sous l'axe pour des libellés pivotés : la largeur du
  /// libellé le plus long (au poids réellement rendu et à l'échelle de texte
  /// courante), plafonnée pour qu'un code aberrant n'écrase pas le graphique.
  double _verticalLabelExtent(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    // Mesurer avec le style effectivement peint : le Text du titre hérite du
    // DefaultTextStyle ambiant (police du thème) avant d'appliquer le nôtre.
    final ambientStyle = DefaultTextStyle.of(context).style;
    var widest = 0.0;
    for (var i = 0; i < items.length; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: items[i].label,
          style: ambientStyle.merge(_bottomLabelStyle(i)),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
    }
    return (widest + AppDimensions.spacingXS).clamp(
      AppDimensions.enrollmentStatsChartBottomTitleHeight,
      AppDimensions.enrollmentStatsChartVerticalLabelMaxExtent,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final topY = (maxVal * 1.25).ceilToDouble().clamp(10.0, double.infinity);
    final barWidth = (items.length > 4 ? 20.0 : 32.0);

    // Des libellés pivotés mangent la hauteur du tracé : on rend au dessinateur
    // ce que l'axe lui prend, pour que les barres gardent leur amplitude.
    final bottomReservedSize = verticalBottomLabels
        ? _verticalLabelExtent(context)
        : AppDimensions.enrollmentStatsChartBottomTitleHeight;
    final chartHeight =
        AppDimensions.enrollmentStatsChartSectionHeight +
        (bottomReservedSize -
            AppDimensions.enrollmentStatsChartBottomTitleHeight);

    return SizedBox(
      height: chartHeight,
      child: ChartEntrance(
        builder: (context, motion) => BarChart(
          BarChartData(
            maxY: topY,
            barTouchData: BarTouchData(
              enabled: !showValueLabels,
              handleBuiltInTouches: !showValueLabels,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => showValueLabels
                    ? Colors.transparent
                    : AppColors.surfaceDark,
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
                  reservedSize: bottomReservedSize,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= items.length) {
                      return const SizedBox.shrink();
                    }
                    final label = Text(
                      items[idx].label,
                      style: _bottomLabelStyle(idx),
                      textAlign: TextAlign.center,
                      maxLines: verticalBottomLabels ? 1 : null,
                      overflow: verticalBottomLabels
                          ? TextOverflow.ellipsis
                          : TextOverflow.clip,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: AppDimensions.spacingXS,
                      ),
                      child: verticalBottomLabels
                          ? RotatedBox(quarterTurns: 1, child: label)
                          : label,
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
                      toY: motion.lerpValue(items[i].value),
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
          duration: motion.duration,
          curve: motion.curve,
        ),
      ),
    );
  }
}
