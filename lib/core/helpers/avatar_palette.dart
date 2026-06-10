import 'package:flutter/painting.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Helper pur attribuant à chaque élève une teinte stable et déterministe.
///
/// La teinte sert d'identité visuelle ; elle ne porte aucune information
/// fonctionnelle (WCAG 1.4.1). Le statut reste véhiculé par la variante de
/// [StudentAvatar] (solid / outlined).
///
/// La teinte est **générée par hue** sur tout le cercle chromatique (variation
/// maximale → très peu de collisions, contrairement à une petite palette fixe),
/// puis **assombrie jusqu'à garantir un contraste AA (≥ 4.5:1)** à la fois pour
/// les initiales blanches sur la teinte (solid) ET pour la teinte sur fond
/// papier (outlined). Le contraste est donc calculé, pas seulement audité.
class AvatarPalette {
  AvatarPalette._();

  static const double _minContrast = 4.5;
  static const double _saturation = 0.50;
  static const double _baseLightness = 0.42;
  static const double _minLightness = 0.16;
  static const double _lightnessStep = 0.03;

  /// Retourne la teinte stable associée à [key] (id élève).
  ///
  /// - Déterministe : une même clé renvoie toujours la même couleur.
  /// - Clé vide → teinte stable de repli (déterministe, AA garanti).
  /// - La clé doit être un identifiant **stable** (id élève) et non le nom,
  ///   pour que la couleur ne change pas si le nom est corrigé.
  static Color colorFor(String key) {
    final effectiveKey = key.isEmpty ? '∅' : key;
    final hue = (_fnv1a(effectiveKey) % 360).toDouble();
    return _aaSafeTint(hue);
  }

  /// Teinte profonde à [hue] donné, assombrie jusqu'à passer AA sur les deux
  /// fonds (blanc cassé en solid, papier en outlined). Les hues clairs (jaune,
  /// vert) sont automatiquement plus assombris que les hues sombres (bleu).
  static Color _aaSafeTint(double hue) {
    var lightness = _baseLightness;
    var color = HSLColor.fromAHSL(1, hue, _saturation, lightness).toColor();
    while (lightness > _minLightness && !_passesAA(color)) {
      lightness -= _lightnessStep;
      color = HSLColor.fromAHSL(1, hue, _saturation, lightness).toColor();
    }
    return color;
  }

  static bool _passesAA(Color tint) =>
      _contrastRatio(tint, AppColors.blancCasse) >= _minContrast &&
      _contrastRatio(tint, AppColors.surfaceAlt) >= _minContrast;

  /// Ratio de contraste WCAG entre deux couleurs (≥ 1).
  static double _contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Hash FNV-1a 32 bits — déterministe et sans dépendance à l'aléatoire.
  static int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
