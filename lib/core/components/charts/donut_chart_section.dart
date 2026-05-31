import 'package:flutter/material.dart';

/// Section de données pour un graphique en anneau (donut).
class DonutChartSection {
  final String label;
  final int count;
  final double percent;
  final Color color;

  const DonutChartSection({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });
}
