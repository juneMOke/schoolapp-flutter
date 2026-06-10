import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Indicateur de progression discret du splash (spec COMPOSANT 03). Barre
/// indéterminée fine, en Or Doux sur une piste blanche translucide.
///
/// Le bootstrap n'expose pas de pourcentage : l'indicateur est volontairement
/// indéterminé. Comme l'arc du symbole, c'est une motion fonctionnelle (état de
/// chargement) : elle défile toujours, indépendamment du réglage « réduire les
/// animations » de l'OS — sinon l'écran d'attente paraît figé/planté.
class SplashProgressBar extends StatelessWidget {
  const SplashProgressBar({super.key, required this.width});

  /// Largeur de la barre (spec §03 : 96 → 130top  → 150 selon le format).
  final double width;

  /// Hauteur de la piste (spec §03 : 4 dp).
  static const double _trackHeight = 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: AppRadius.brPill,
        child: LinearProgressIndicator(
          minHeight: _trackHeight,
          color: AppColors.orDoux,
          backgroundColor: AppColors.blancCasse.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}
