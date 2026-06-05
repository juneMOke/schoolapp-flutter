import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Barre de progression fine du stepper d'inscription (PARCOURS 18).
///
/// Piste `surface-alt`, remplissage en dégradé terre-cuite → or-doux,
/// transition animée (220 ms) à chaque changement d'étape. Respecte
/// reduced-motion via [reduceMotion] (transition instantanée si vrai).
class WizardProgressBar extends StatelessWidget {
  final double progress;
  final bool reduceMotion;

  const WizardProgressBar({
    super.key,
    required this.progress,
    this.reduceMotion = false,
  });

  static const double _height = 4;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_height / 2),
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.surfaceAlt),
            Align(
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: clamped),
                duration: reduceMotion ? Duration.zero : AppMotion.standard,
                curve: AppMotion.outCurve,
                builder: (context, value, child) => FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: child,
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.terreCuite, AppColors.orDoux],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
