import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Carte surélevée du module résultats (radius 16, ombre de carte, bordure fine)
/// — conteneur commun de la carte de recherche, de la synthèse, de la table et
/// des blocs du focus, pour une géométrie cohérente.
class ResultatsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final EdgeInsetsGeometry margin;

  const ResultatsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.background,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background ?? AppColors.surfaceRaised,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.border),
          boxShadow: AppElevation.shadowCard,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
