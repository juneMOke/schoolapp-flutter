import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:school_app_flutter/core/branding/branding_assets.dart';

/// Variantes officielles du logo ETEELO CONNECT.
///
/// Les six premières variantes existent en SVG dans le kit branding.
/// Toute variante non listée ici est interdite — passer par le kit source.
enum EteeloLogoVariant {
  /// Symbole seul, fond clair. Variante par défaut. AppBar, drawer fond clair.
  symbolOnLight,

  /// Symbole seul, fond foncé (arc Or Doux). Drawer Bleu Profond, hero foncé.
  symbolOnDark,

  /// Symbole monochrome bleu profond. Impression 1 couleur, en-tête PDF.
  symbolMono,

  /// Symbole en silhouette blanche. Fonds chargés, photographies de fond.
  symbolSilhouette,

  /// Logo horizontal complet (symbole + "ETEELO CONNECT") sur fond clair.
  /// Splash Flutter, écran de connexion, en-tête de PDF, footer.
  horizontalOnLight,

  /// Logo horizontal complet sur fond foncé.
  horizontalOnDark,
}

/// Composant officiel du logo ETEELO CONNECT pour l'application produit.
///
/// Toujours utiliser ce composant pour afficher le logo, jamais
/// `SvgPicture.asset` direct. Cela garantit que :
/// - Le bon asset est servi pour la variante demandée.
/// - Une évolution de la charte (v3.0 future) ne demande qu'une modification
///   ici, pas une chasse aux chemins en dur dans toute l'app.
/// - L'accessibilité (semanticsLabel) est gérée de manière centrale.
///
/// ## Exemple — symbole seul dans le drawer Bleu Profond
///
/// ```dart
/// EteeloLogo(
///   variant: EteeloLogoVariant.symbolOnDark,
///   size: 36,
/// )
/// ```
///
/// ## Exemple — logo horizontal au splash Flutter
///
/// ```dart
/// EteeloLogo(
///   variant: EteeloLogoVariant.horizontalOnLight,
///   size: 60, // hauteur ; la largeur s'adapte automatiquement
/// )
/// ```
class EteeloLogo extends StatelessWidget {
  /// Variante du logo à afficher.
  final EteeloLogoVariant variant;

  /// Hauteur du logo en logical pixels (dp).
  ///
  /// Si `null`, le SVG prend sa taille intrinsèque définie par son viewBox.
  /// Pour les usages contraints (AppBar, drawer), passer une taille explicite.
  final double? size;

  /// Libellé accessibilité. Si `null`, un libellé par défaut est calculé
  /// depuis la variante.
  final String? semanticsLabel;

  /// Forcer la couleur du SVG (rare). Utile pour le symbole monochrome
  /// quand on veut le teinter (ex: en `AppColors.bleuProfond` sur fond crème,
  /// en `AppColors.blancCasse` sur fond foncé). Pour les autres variantes,
  /// laisser `null` — la couleur est portée par le SVG lui-même.
  final Color? colorOverride;

  const EteeloLogo({
    super.key,
    this.variant = EteeloLogoVariant.symbolOnLight,
    this.size,
    this.semanticsLabel,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetForVariant(variant),
      height: size,
      semanticsLabel: semanticsLabel ?? _defaultSemanticsLabel(variant),
      colorFilter: colorOverride != null
          ? ColorFilter.mode(colorOverride!, BlendMode.srcIn)
          : null,
      // Placeholder pendant le chargement asynchrone du SVG ; évite un saut
      // de layout. La taille du placeholder matche celle finale.
      placeholderBuilder: (_) => SizedBox(height: size, width: size),
    );
  }

  String _assetForVariant(EteeloLogoVariant v) {
    switch (v) {
      case EteeloLogoVariant.symbolOnLight:
        return BrandingAssets.symboleColor;
      case EteeloLogoVariant.symbolOnDark:
        return BrandingAssets.symboleDarkBg;
      case EteeloLogoVariant.symbolMono:
        return BrandingAssets.symboleMono;
      case EteeloLogoVariant.symbolSilhouette:
        return BrandingAssets.symboleSilhouette;
      case EteeloLogoVariant.horizontalOnLight:
        return BrandingAssets.logoHorizontalColor;
      case EteeloLogoVariant.horizontalOnDark:
        return BrandingAssets.logoHorizontalDarkBg;
    }
  }

  String _defaultSemanticsLabel(EteeloLogoVariant v) {
    // Tous les libellés disent la même chose à un lecteur d'écran : c'est
    // le logo ETEELO CONNECT. La nuance de variante n'est pas pertinente
    // pour l'accessibilité, c'est une question d'apparence.
    return 'Logo ETEELO CONNECT';
  }
}
