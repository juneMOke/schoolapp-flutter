import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/branding/auth/auth_brand_content.dart';
import 'package:school_app_flutter/core/branding/eteelo_lockup.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';

/// Forme du panneau de marque selon la largeur (charte Connexion §01).
/// - [split] : colonne pleine hauteur (≥ 900 dp).
/// - [band]  : bandeau haut, lockup + titre condensé (560–900 dp).
/// - [slim]  : bandeau fin, lockup seul (< 560 dp).
enum BrandPanelVariant { split, band, slim }

/// Panneau de marque ETEELO CONNECT partagé par les écrans d'auth
/// (connexion + réinitialisation). Le rendu est identique ; seul le contenu
/// éditorial ([AuthBrandContent]) diffère.
///
/// Rôle purement éditorial → décoratif pour l'accessibilité
/// ([ExcludeSemantics]) : le lecteur d'écran ne lit pas la marque deux fois.
class AuthBrandPanel extends StatelessWidget {
  final BrandPanelVariant variant;
  final AuthBrandContent content;

  const AuthBrandPanel({
    super.key,
    required this.variant,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.bleuProfond),
        child: Stack(
          children: [const KubaPatternLayer(), _filigrane(), _content()],
        ),
      ),
    );
  }

  /// Filigrane « E » (symbole) débordant à droite — dimension/position selon la
  /// variante. Sur le bandeau slim/band, le Stack le clippe à la hauteur du
  /// bandeau, d'où l'effet de débordement à l'extrême droite (charte §01).
  Widget _filigrane() {
    switch (variant) {
      case BrandPanelVariant.split:
        return const _Filigrane(size: 150, right: -34, opacity: 0.07);
      case BrandPanelVariant.band:
        return const _Filigrane(size: 128, right: -30, opacity: 0.09);
      case BrandPanelVariant.slim:
        return const _Filigrane(size: 116, right: -26, opacity: 0.10);
    }
  }

  Widget _content() {
    switch (variant) {
      case BrandPanelVariant.split:
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EteeloLockup(symbolSize: 40),
                  const SizedBox(height: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: _BrandTitle(
                      title: content.title,
                      highlight: content.highlight,
                      fontSize: 27,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Text(
                      content.subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.blancCasse.withValues(alpha: 0.80),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case BrandPanelVariant.band:
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EteeloLockup(symbolSize: 36),
                const SizedBox(height: 14),
                _BrandTitle(
                  title: content.condensedTitle,
                  highlight: content.highlight,
                  fontSize: 20,
                ),
              ],
            ),
          ),
        );
      case BrandPanelVariant.slim:
        return const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 26, vertical: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: EteeloLockup(symbolSize: 34),
            ),
          ),
        );
    }
  }
}

/// Titre éditorial Lora avec le mot accentué en Or Doux (charte §01).
class _BrandTitle extends StatelessWidget {
  final String title;
  final String highlight;
  final double fontSize;

  const _BrandTitle({
    required this.title,
    required this.highlight,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: 'Lora',
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.16,
      color: AppColors.blancCasse,
    );
    final index = title.indexOf(highlight);
    if (index < 0) return Text(title, style: base);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: title.substring(0, index)),
          TextSpan(
            text: highlight,
            style: const TextStyle(color: AppColors.orDoux),
          ),
          TextSpan(text: title.substring(index + highlight.length)),
        ],
      ),
    );
  }
}

/// « E » blanc semi-transparent (symbole silhouette) débordant à droite du
/// panneau/bandeau (charte §01, filigrane). Le SVG silhouette a des fills
/// directs (pas de `<style>`) → rendu fiable, contrairement au logo horizontal.
class _Filigrane extends StatelessWidget {
  final double size;
  final double right;
  final double opacity;

  const _Filigrane({
    required this.size,
    required this.right,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      right: right,
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: EteeloLogo(
            variant: EteeloLogoVariant.symbolSilhouette,
            size: size,
          ),
        ),
      ),
    );
  }
}
