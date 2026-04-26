import 'package:flutter/animation.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Tokens d'animation du module Finance.
///
/// Backward-compatible: conserve l'API FinanceMotion tout en deleguant
/// les valeurs a AppMotion (source unique transverse).
class FinanceMotion {
  const FinanceMotion._();

  // Durations
  static const Duration micro = AppMotion.micro;
  static const Duration fast = AppMotion.fast;
  static const Duration medium = AppMotion.medium;
  static const Duration standard = AppMotion.standard;
  static const Duration entrance = AppMotion.entrance;

  // Curves
  static const Curve inCurve = AppMotion.inCurve;
  static const Curve outCurve = AppMotion.outCurve;
  static const Curve gentleOut = AppMotion.gentleOut;
}