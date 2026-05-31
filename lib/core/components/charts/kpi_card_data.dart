import 'package:flutter/material.dart';

/// Données génériques pour une carte KPI.
class KpiCardData {
  final String label;
  final int value;
  final int? percent;
  final Color accent;
  final Color accentSoft;
  final IconData icon;

  const KpiCardData({
    required this.label,
    required this.value,
    required this.accent,
    required this.accentSoft,
    required this.icon,
    this.percent,
  });
}
