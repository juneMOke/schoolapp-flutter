import 'package:flutter/material.dart';

/// Une part d'une barre **empilée** : sa valeur, sa teinte et son nom.
///
/// Le nom sert à la bulle et à la légende : la couleur ne porte jamais seule
/// l'information.
class BarChartSegment {
  final String label;
  final double value;
  final Color color;

  const BarChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}
