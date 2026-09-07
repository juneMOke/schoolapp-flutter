import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

// Ce que le tracé de CycleBarChart doit MESURER avant de se peindre.
//
// Séparé du dessin parce que ce sont deux métiers : ici on ne produit que des
// nombres, et ils s'éprouvent sans monter un graphique.

/// Largeur d'une barre — une **part du pas**, jamais une valeur absolue.
///
/// La version précédente posait `barCount > 4 ? 20 : 32`, une largeur en dur
/// sans rapport avec l'espace réellement disponible : à cinq barres dans une
/// carte large, 20 dp ne faisaient que ~23 % du pas là où la spec en demande
/// 53 % (46/86), et le rythme se lisait comme une rangée de traits.
///
/// [availableWidth] non bornée (tracé posé dans un contexte de largeur
/// infinie) : on retombe sur la largeur maximale, faute de pas mesurable.
double cycleBarWidth({required int barCount, required double availableWidth}) {
  if (barCount <= 0 || !availableWidth.isFinite) {
    return AppDimensions.enrollmentStatsChartBarMaxWidth;
  }
  final plotWidth =
      availableWidth - AppDimensions.enrollmentStatsChartLeftAxisWidth;
  if (plotWidth <= 0) return AppDimensions.enrollmentStatsChartBarMinWidth;

  final pitch = plotWidth / barCount;
  return (pitch * AppDimensions.enrollmentStatsChartBarWidthRatio).clamp(
    AppDimensions.enrollmentStatsChartBarMinWidth,
    AppDimensions.enrollmentStatsChartBarMaxWidth,
  );
}

/// Hauteur à réserver sous l'axe pour des libellés pivotés : la largeur du
/// libellé le plus long (au poids réellement rendu et à l'échelle de texte
/// courante), plafonnée pour qu'un code aberrant n'écrase pas le graphique.
double cycleBarBottomLabelExtent({
  required BuildContext context,
  required List<BarChartItem> items,
  required TextStyle Function(int index) styleOf,
}) {
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
        style: ambientStyle.merge(styleOf(i)),
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
