import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/chart_height.dart';
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

  /// Étiquette **en permanence** les barres mises en relief, même quand
  /// [showValueLabels] est faux.
  ///
  /// ⚠️ **Pour un écran qui n'a pas d'axe vertical.** Sans axe et sans
  /// étiquettes — le cas d'une fenêtre large, où l'on renonce à chiffrer chaque
  /// barre — le relief ne repose plus que sur la **couleur**. Un lecteur qui ne
  /// distingue pas les deux teintes perd alors l'intervalle en cours, et il n'a
  /// aucun chiffre nulle part pour le retrouver.
  ///
  /// Défaut faux : les appelants qui gardent leur axe n'en ont pas besoin, et
  /// leur rendu ne bouge pas.
  final bool labelHighlightedBars;

  /// Ce que fait un toucher sur une barre, avec son index. `null` — le
  /// défaut — : les barres se lisent sans s'ouvrir.
  ///
  /// ⚠️ Le tracé n'est pas atteignable au lecteur d'écran : un écran qui ouvre
  /// une barre au toucher offre aussi un autre chemin (liste, sélecteur).
  final ValueChanged<int>? onBarTap;

  /// Liseré des barres mises en relief, ou `null` — le défaut — pour n'en
  /// marquer que le libellé. Utile sur une barre **empilée**, dont la teinte
  /// ne peut pas porter le relief : ses parts ont déjà chacune la leur.
  final Color? highlightBorderColor;

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
    this.labelHighlightedBars = false,
    this.onBarTap,
    this.highlightBorderColor,
  });

  /// La bulle d'une barre empilée : son libellé, puis chaque part non nulle.
  String _stackedTooltip(BarChartItem item) {
    final format =
        valueLabelFormatter ?? NumberFormatterHelper.formatYAxisLabel;
    return [
      item.label,
      for (final segment in item.segments)
        if (segment.value > 0) '${segment.label} : ${format(segment.value)}',
    ].join('\n');
  }

  /// La barre [i] telle que fl_chart la dessine, à l'instant [lerp] de
  /// l'entrée.
  BarChartRodData _rod(
    int i, {
    required double barWidth,
    required double minToY,
    required double Function(double) lerp,
  }) {
    final item = items[i];
    final border =
        highlightBorderColor != null && highlightedIndexes.contains(i)
        ? BorderSide(
            color: highlightBorderColor!,
            width: AppDimensions.chartHighlightBorderWidth,
          )
        : null;
    if (item.isStacked) {
      // Une barre empilée mesure exactement la somme de ses parts : aucun
      // plancher, qui fausserait la proportion entre elles. Une part nulle
      // reste dans la pile (hauteur zéro) : l'animation interpole part à
      // part, et une pile qui changerait de longueur mêlerait leurs teintes.
      var from = 0.0;
      final stack = <BarChartRodStackItem>[];
      for (final segment in item.segments) {
        final to = from + (segment.value < 0 ? 0 : segment.value);
        stack.add(BarChartRodStackItem(lerp(from), lerp(to), segment.color));
        from = to;
      }
      return BarChartRodData(
        toY: lerp(from),
        color: item.color,
        rodStackItems: stack,
        width: barWidth,
        borderRadius: BorderRadius.circular(barRadius),
        borderSide: border,
        backDrawRodData: _tapColumn(),
      );
    }
    return BarChartRodData(
      // Zéro reste zéro : le plancher ne s'applique qu'à une valeur réellement
      // encaissée.
      toY: lerp(
        item.value <= 0
            ? item.value
            : (item.value < minToY ? minToY : item.value),
      ),
      color: item.color,
      width: barWidth,
      borderRadius: BorderRadius.circular(barRadius),
      borderSide: border,
      backDrawRodData: _tapColumn(),
    );
  }

  /// Le haut de l'axe : 25 % au-dessus de la plus haute barre, jamais sous
  /// [minTop].
  double get _topY {
    final maxVal = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return (maxVal * 1.25).ceilToDouble().clamp(minTop, double.infinity);
  }

  /// Le fond invisible d'une barre qui s'ouvre : il porte le toucher sur
  /// toute la hauteur du tracé.
  BackgroundBarChartRodData? _tapColumn() => onBarTap == null
      ? null
      : BackgroundBarChartRodData(
          show: true,
          toY: _topY,
          color: Colors.transparent,
        );

  /// Cette barre porte-t-elle son montant en permanence ?
  bool _labelsAlways(int index) =>
      showValueLabels ||
      (labelHighlightedBars && highlightedIndexes.contains(index));

  /// Style du libellé sous l'axe pour la barre [index].
  /// Sert aussi bien au rendu qu'à la mesure de la hauteur à réserver.
  /// Le style d'un libellé d'axe — **et la mesure de la place qu'il prend**.
  ///
  /// Chiffres tabulaires : l'axe est une **rangée de nombres** — des jours, des
  /// mois, des semaines — et sans largeur fixe le « 11 » et le « 08 » ne
  /// tombent pas au même endroit sous leurs barres. Le décalage est d'un
  /// pixel ou deux par libellé, mais il se cumule sur trente et un jours et
  /// fait onduler l'axe.
  ///
  /// La même fonction sert à mesurer la hauteur réservée aux libellés pivotés :
  /// le calcul suit donc le changement de largeur sans qu'on ait à y penser.
  TextStyle _bottomLabelStyle(int index) {
    final highlighted = highlightedIndexes.contains(index);
    return AppTextStyles.caption.copyWith(
      color: highlighted ? AppColors.textPrimary : AppColors.textSecondary,
      fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
      fontFeatures: AppTextStyles.tabularFigures,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final topY = _topY;

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
    // La hauteur suit la largeur offerte (`ChartHeight`), plus ce que les
    // libellés pivotés prennent.
    return LayoutBuilder(
      builder: (context, outer) {
        final chartHeight =
            ChartHeight.forWidth(
              outer.maxWidth,
              min: AppDimensions.enrollmentStatsChartSectionHeight,
            ) +
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
                      enabled: !showValueLabels || onBarTap != null,
                      handleBuiltInTouches: !showValueLabels,
                      // Une barre qui s'ouvre se touche sur toute sa colonne,
                      // pas sur ses seuls pixels : une barre basse (ou nulle)
                      // reste une cible d'au moins 48 dp.
                      allowTouchBarBackDraw: onBarTap != null,
                      touchExtraThreshold: onBarTap == null
                          ? null
                          : EdgeInsets.symmetric(
                              horizontal:
                                  (AppDimensions.minTouchTarget - barWidth)
                                      .clamp(4, AppDimensions.minTouchTarget) /
                                  2,
                            ),
                      touchCallback: onBarTap == null
                          ? null
                          : (event, response) {
                              final spot = response?.spot;
                              if (event is FlTapUpEvent && spot != null) {
                                onBarTap!(spot.touchedBarGroupIndex);
                              }
                            },
                      mouseCursorResolver: onBarTap == null
                          ? null
                          : (event, response) => response?.spot == null
                                ? MouseCursor.defer
                                : SystemMouseCursors.click,
                      touchTooltipData: BarTouchTooltipData(
                        // Transparent sous une étiquette permanente : c'est un
                        // montant posé sur la barre, pas une bulle.
                        getTooltipColor: (group) =>
                            _labelsAlways(group.x.toInt())
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
                          // ⚠️ **L'étiquette lit la valeur de l'ITEM, jamais
                          // `rod.toY`.** Les deux ne sont pas le même nombre depuis
                          // qu'un plancher existe : une barre de 300 sous un maximum
                          // à 7 000 000 est dessinée à 91 145 pour rester visible, et
                          // une étiquette prise sur la géométrie annonçait « 91 K »
                          // là où l'école avait encaissé 300. Sur un écran d'argent,
                          // un chiffre faux est pire qu'une barre invisible.
                          //
                          // Le plancher est une décision de DESSIN ; l'étiquette est
                          // une donnée. Elles n'ont pas à passer par la même valeur.
                          final value = item.value;
                          if (_labelsAlways(group.x.toInt())) {
                            // Étiquette permanente : valeur seule ; couleur dédiée si
                            // fournie (sinon couleur de la barre).
                            return BarTooltipItem(
                              (valueLabelFormatter ??
                                  NumberFormatterHelper.formatYAxisLabel)(
                                value,
                              ),
                              AppTextStyles.caption.copyWith(
                                color:
                                    valueLabelColorBuilder?.call(
                                      group.x.toInt(),
                                    ) ??
                                    item.color,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTextStyles.tabularFigures,
                              ),
                            );
                          }
                          return BarTooltipItem(
                            item.isStacked
                                ? _stackedTooltip(item)
                                : '${item.label}\n${NumberFormatterHelper.formatYAxisLabel(value)}',
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
                          showingTooltipIndicators: _labelsAlways(i)
                              ? const [0]
                              : const [],
                          barRods: [
                            _rod(
                              i,
                              barWidth: barWidth,
                              minToY: minToY,
                              lerp: motion.lerpValue,
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
      },
    );
  }
}
