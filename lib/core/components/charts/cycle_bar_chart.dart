import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/chart_entrance.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart_geometry.dart';
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

  /// Plancher du domaine haut de l'axe, avant la marge de 25 %.
  ///
  /// Le défaut de 10 existe pour qu'une série minuscule ne dessine pas des
  /// barres pleine hauteur sur un axe de 1 ou 2 — ce qui donnerait à un jour
  /// creux l'allure d'un pic. Il convient aux séries financières, comptées en
  /// centimes, où il n'est jamais atteint.
  ///
  /// Il ne convient PAS aux petits comptages : à 1 à 3 inscriptions par jour,
  /// un plancher de 10 écrase toutes les barres contre l'axe, tous les jours,
  /// et le rythme devient illisible précisément là où il compte. Ces
  /// appelants-là passent un plancher plus bas.
  final double minTop;

  /// Rayon du sommet des barres.
  final double barRadius;

  /// Nombre d'intervalles de grille — une ligne de plus que d'intervalles.
  final int gridDivisions;

  /// Dessine l'axe vertical et ses libellés de valeurs.
  ///
  /// ⚠️ **Un écran qui pose les montants SUR les barres n'en veut pas** : le
  /// même chiffre s'écrirait alors deux fois, une fois au sommet de la barre et
  /// une fois sur l'axe. Le laisser vaut quand les barres ne portent pas leur
  /// valeur, l'axe étant alors le seul repère chiffré.
  ///
  /// Défaut `true` — le rendu historique, que les appelants existants gardent.
  final bool showLeftAxis;

  /// Hauteur minimale, **en dp**, d'une barre dont la valeur n'est pas nulle.
  ///
  /// ⚠️ Sans plancher, une valeur réelle mais très petite sous un maximum très
  /// grand rend une barre d'une fraction de pixel — **indiscernable d'un
  /// zéro**. Le plancher la rend visible.
  ///
  /// **Zéro reste zéro** : le plancher ne relève jamais une valeur nulle, ce
  /// qui ferait voir une donnée là où il n'y en a pas. C'est la même règle que
  /// sur les lignes-barres du socle.
  final double minimumBarHeight;

  const CycleBarChart({
    super.key,
    required this.items,
    this.highlightedIndexes = const <int>{},
    this.showValueLabels = false,
    this.verticalBottomLabels = false,
    this.valueLabelFormatter,
    this.valueLabelColorBuilder,
    this.minTop = 10.0,
    this.barRadius = AppDimensions.enrollmentStatsChartBorderRadius,
    this.gridDivisions = AppDimensions.enrollmentStatsChartGridDivisions,
    this.showLeftAxis = true,
    this.minimumBarHeight = 0,
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

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final topY = (maxVal * 1.25).ceilToDouble().clamp(minTop, double.infinity);

    // Des libellés pivotés mangent la hauteur du tracé : on rend au dessinateur
    // ce que l'axe lui prend, pour que les barres gardent leur amplitude.
    final axisWidth = showLeftAxis
        ? AppDimensions.enrollmentStatsChartLeftAxisWidth
        : 0.0;
    final bottomReservedSize = verticalBottomLabels
        ? cycleBarBottomLabelExtent(
            context: context,
            items: items,
            styleOf: _bottomLabelStyle,
          )
        : AppDimensions.enrollmentStatsChartBottomTitleHeight;
    final chartHeight =
        AppDimensions.enrollmentStatsChartSectionHeight +
        (bottomReservedSize -
            AppDimensions.enrollmentStatsChartBottomTitleHeight);

    return SizedBox(
      height: chartHeight,
      // La largeur des barres se déduit du pas, donc de la largeur offerte :
      // il faut l'avoir mesurée avant de construire le tracé.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = cycleBarWidth(
            barCount: items.length,
            availableWidth: constraints.maxWidth,
            axisWidth: axisWidth,
          );

          // Le plancher est donné en dp ; les barres, elles, se mesurent dans
          // l'unité des données. On convertit donc avec la hauteur réellement
          // offerte au tracé — sans quoi le même plancher vaudrait deux choses
          // différentes sur deux graphiques de hauteurs différentes.
          final plotHeight = chartHeight - bottomReservedSize;
          final minToY = (minimumBarHeight <= 0 || plotHeight <= 0)
              ? 0.0
              : topY * (minimumBarHeight / plotHeight);
          return ChartEntrance(
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
                        : const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                  horizontalInterval: (topY / gridDivisions).clamp(
                    1,
                    double.infinity,
                  ),
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
                      showTitles: showLeftAxis,
                      reservedSize: axisWidth,
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
                          // Zéro reste zéro : le plancher ne s'applique qu'à
                          // une valeur réellement encaissée.
                          toY: motion.lerpValue(
                            items[i].value <= 0
                                ? items[i].value
                                : (items[i].value < minToY
                                      ? minToY
                                      : items[i].value),
                          ),
                          color: items[i].color,
                          width: barWidth,
                          borderRadius: BorderRadius.circular(barRadius),
                        ),
                      ],
                    ),
                ],
              ),
              duration: motion.duration,
              curve: motion.curve,
            ),
          );
        },
      ),
    );
  }
}
