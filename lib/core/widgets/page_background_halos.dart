import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Transform pour un gradient radial avec ellipse (rapport d'aspect custom).
/// Permet de scaler l'espace du gradient autour du centre pour produire
/// une ellipse fidèle au lieu d'un cercle.
class EllipseGradientTransform extends GradientTransform {
  final Alignment center;
  final double scaleX;
  final double scaleY;

  const EllipseGradientTransform({
    required this.center,
    required this.scaleX,
    required this.scaleY,
  });

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final c = center.withinRect(bounds);
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(scaleX, scaleY, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1);
  }
}

/// Widget renderant les deux halos elliptiques dégradés (bleu + terre-cuite).
/// Chaque halo est un RadialGradient avec EllipseGradientTransform pour
/// produire une forme d'ellipse plutôt qu'un cercle.
///
/// L'ensemble est enveloppé dans un RepaintBoundary pour éviter les
/// redesseins inutiles au scroll.
class PageBackgroundHalos extends StatelessWidget {
  const PageBackgroundHalos({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Halo bleu (haut-droit)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(
                    AppDimensions.pageHaloBlueAlign,
                    AppDimensions.pageHaloBlueAlignY,
                  ),
                  radius: AppDimensions.pageHaloRadius,
                  colors: [
                    AppColors.pageBackgroundHaloBlue.withValues(
                      alpha: AppDimensions.pageHaloBlueOpacity,
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.60],
                  transform: const EllipseGradientTransform(
                    center: Alignment(
                      AppDimensions.pageHaloBlueAlign,
                      AppDimensions.pageHaloBlueAlignY,
                    ),
                    scaleX: AppDimensions.pageHaloBlueRatio,
                    scaleY: 1.0,
                  ),
                ),
              ),
            ),
          ),
          // Halo terre-cuite (bas-gauche)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(
                    AppDimensions.pageHaloTerraAlign,
                    AppDimensions.pageHaloTerraAlignY,
                  ),
                  radius: AppDimensions.pageHaloRadius,
                  colors: [
                    AppColors.pageBackgroundHaloTerracotta.withValues(
                      alpha: AppDimensions.pageHaloTerraOpacity,
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55],
                  transform: const EllipseGradientTransform(
                    center: Alignment(
                      AppDimensions.pageHaloTerraAlign,
                      AppDimensions.pageHaloTerraAlignY,
                    ),
                    scaleX: AppDimensions.pageHaloTerraRatio,
                    scaleY: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
