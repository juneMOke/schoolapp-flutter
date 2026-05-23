import 'package:flutter/material.dart';

/// Barre de données pour un graphique en barres.
class BarChartItem {
  final String label;
  final double value;
  final Color color;

  const BarChartItem({
    required this.label,
    required this.value,
    required this.color,
  });
}
