import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Carte d'en-tête à **liséré gauche coloré** (5 dp) : en-tête d'un cours,
/// d'un programme, d'un chapitre.
///
/// Le liséré est un fond accent révélé sur 5 dp, et non une `Row` étirée, qui
/// planterait dans une vue défilante (hauteur non bornée).
class AccentEdgeCard extends StatelessWidget {
  final Color accent;
  final Widget child;

  const AccentEdgeCard({super.key, required this.accent, required this.child});

  static const double edgeWidth = 5;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brCard,
      child: ColoredBox(
        color: accent,
        child: Padding(
          padding: const EdgeInsets.only(left: edgeWidth),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceRaised,
              border: Border(
                top: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
