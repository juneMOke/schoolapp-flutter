import 'package:flutter/animation.dart';

/// Tokens d'animation du module Finance.
///
/// Objectif: harmoniser les interactions et faciliter un tuning global.
class FinanceMotion {
  const FinanceMotion._();

  // Durations
  static const Duration micro = Duration(milliseconds: 130);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration entrance = Duration(milliseconds: 260);

  // Curves
  static const Curve inCurve = Curves.easeInCubic;
  static const Curve outCurve = Curves.easeOutCubic;
  static const Curve gentleOut = Curves.easeOut;
}
