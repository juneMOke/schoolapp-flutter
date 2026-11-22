import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';

/// La piste (poids) et son remplissage (taux), en dégradé de la couleur du
/// frais — `FinBarRows` de la maquette.
class RecoveryRateTrackBar extends StatelessWidget {
  final Color color;
  final double weight;
  final double fill;

  const RecoveryRateTrackBar({
    super.key,
    required this.color,
    required this.weight,
    required this.fill,
  });

  /// Les mélanges de la maquette : piste à 8 %, bord à 18 %, dégradé à 78 %.
  static const int _trackPercent = 8;
  static const int _borderPercent = 18;
  static const double _gradientStart = 0.78;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final radius = BorderRadius.circular(
      AppDimensions.recouvrementRateBarRadius,
    );

    Widget barAt(double t) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: weight,
      child: Container(
        height: AppDimensions.recouvrementRateBarHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ColorMix.tint(AppColors.surfaceAlt, color, _trackPercent),
          borderRadius: radius,
          border: Border.all(
            color: ColorMix.tint(AppColors.border, color, _borderPercent),
          ),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: (fill * t).clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: _gradientStart),
                  color,
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return ExcludeSemantics(
      child: reduceMotion
          ? barAt(1)
          : TweenAnimationBuilder<double>(
              key: ValueKey<double>(fill),
              tween: Tween<double>(begin: 0, end: 1),
              duration: AppMotion.layout,
              curve: AppMotion.outCurve,
              builder: (context, t, _) => barAt(t),
            ),
    );
  }
}
