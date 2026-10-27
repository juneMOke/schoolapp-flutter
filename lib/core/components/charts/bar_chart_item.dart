import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_segment.dart';

/// Barre de données pour un graphique en barres.
class BarChartItem {
  final String label;
  final double value;
  final Color color;

  /// Les parts d'une barre **empilée**, de bas en haut. Vide — le défaut — la
  /// barre est d'une seule teinte, [color].
  ///
  /// Empilée, la barre mesure la somme de ses parts ; [value] doit valoir
  /// cette somme (c'est elle que l'échelle et l'étiquette lisent).
  final List<BarChartSegment> segments;

  const BarChartItem({
    required this.label,
    required this.value,
    required this.color,
    this.segments = const [],
  });

  /// Une barre empilée : sa valeur est la somme de ses parts.
  factory BarChartItem.stacked({
    required String label,
    required List<BarChartSegment> segments,
    required Color color,
  }) => BarChartItem(
    label: label,
    value: segments.fold(0.0, (sum, segment) => sum + segment.value),
    color: color,
    segments: segments,
  );

  bool get isStacked => segments.isNotEmpty;
}
