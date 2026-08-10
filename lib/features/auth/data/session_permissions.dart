import 'dart:convert';

/// Normalisation et sérialisation de l'ensemble des permissions de session
/// (ADR-014 §4).
///
/// Les permissions sont un **ensemble ouvert de chaînes** : le catalogue serveur
/// peut grandir sans release de l'application, donc aucune valeur n'est validée
/// contre une énumération — les inconnues sont conservées telles quelles et
/// ignorées à l'usage. Toute lecture douteuse (champ absent, `null`, type
/// inattendu, JSON illisible) retombe sur l'**ensemble vide** : aucun droit,
/// donc aucun module visible (fail-closed).
///
/// Le stockage se fait en JSON plutôt qu'en chaîne jointe : l'ensemble étant
/// ouvert, aucun séparateur ne peut être garanti absent des valeurs futures.
abstract final class SessionPermissions {
  /// Ensemble vide — aucun droit. Valeur de repli de toutes les lectures.
  static const List<String> none = <String>[];

  /// Normalise une valeur brute issue du fil (`json['permissions']`) ou d'un
  /// JSON relu : entrées non-chaînes, vides et doublons écartés sans erreur,
  /// espaces rognés, ordre d'émission préservé.
  static List<String> sanitize(Object? raw) {
    if (raw is! List) return none;
    final result = <String>[];
    for (final entry in raw) {
      if (entry is! String) continue;
      final value = entry.trim();
      if (value.isEmpty || result.contains(value)) continue;
      result.add(value);
    }
    return List<String>.unmodifiable(result);
  }

  /// Sérialise pour le stockage (secure storage ou colonne SQLCipher).
  static String encode(List<String> permissions) => jsonEncode(permissions);

  /// Relit une valeur stockée. Un contenu absent, vide ou corrompu vaut
  /// [none] — on ne rend jamais de droits sur une lecture douteuse.
  static List<String> decode(String? raw) {
    if (raw == null || raw.isEmpty) return none;
    try {
      return sanitize(jsonDecode(raw));
    } on FormatException {
      return none;
    }
  }
}
