import 'package:flutter/animation.dart';

/// Tokens motion UI globaux (animations + throttling d'actions UI).
/// Source unique pour les surfaces UI transverses (Home, Enrollment, Finance, ...).
class AppMotion {
  const AppMotion._();

  static const Duration micro = Duration(milliseconds: 130);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration entrance = Duration(milliseconds: 260);
  static const Duration layout = Duration(milliseconds: 280);
  static const Duration actionCooldown = Duration(milliseconds: 600);
  static const Duration refreshCooldown = Duration(milliseconds: 700);
  static const Duration tooltipShowDuration = Duration(seconds: 3);

  static const Curve inCurve = Curves.easeInCubic;
  static const Curve outCurve = Curves.easeOutCubic;
  static const Curve gentleOut = Curves.easeOut;
}