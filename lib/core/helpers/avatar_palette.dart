import 'package:flutter/painting.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Helper pur attribuant à chaque élève une teinte stable et déterministe.
///
/// La couleur sert d'identité visuelle (palette tournante) ; elle ne porte
/// aucune information fonctionnelle (WCAG 1.4.1). Le statut reste véhiculé par
/// la variante de [StudentAvatar] (solid / outlined).
///
/// Toutes les teintes sont auditées AA (≥ 4.5:1) dans les deux variantes —
/// voir le commentaire d'audit dans [AppColors].
class AvatarPalette {
  AvatarPalette._();

  /// Palette ordonnée des teintes d'identité. L'ordre est figé : le modifier
  /// réattribue les couleurs des élèves existants.
  static const List<Color> palette = [
    AppColors.bleuArdoise,
    AppColors.avatarTerreCuiteFonce,
    AppColors.vertSavane,
    AppColors.avatarIndigoArdoise,
    AppColors.avatarPrune,
    AppColors.avatarPetrole,
    AppColors.avatarOlive,
    AppColors.avatarBordeaux,
  ];

  /// Retourne la teinte stable associée à [key] (id élève).
  ///
  /// - Déterministe : une même clé renvoie toujours la même couleur.
  /// - Clé vide → première teinte (fallback stable, jamais d'exception).
  /// - La clé doit être un identifiant **stable** (id élève) et non le nom,
  ///   pour que la couleur ne change pas si le nom est corrigé.
  static Color colorFor(String key) {
    if (key.isEmpty) return palette.first;
    return palette[_fnv1a(key) % palette.length];
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
