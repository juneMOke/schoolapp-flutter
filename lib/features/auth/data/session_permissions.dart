import 'dart:convert';

/// Normalisation et sérialisation de l'ensemble des permissions de session
/// (ADR-014 §4).
///
/// **Trois états, jamais deux.** `null` = ensemble inconnu (le serveur ne l'a
/// pas communiqué, ou rien n'a encore été enregistré localement) ; liste vide =
/// aucun droit, ce qui est une information ; liste peuplée = droits connus.
///
/// La distinction porte, et elle a déjà coûté une fois : replier « je ne sais
/// pas » sur « rien » transforme une montée de version — colonne ajoutée sans
/// backfill, clé de storage absente — en retrait total de droits pour tout le
/// parc, coupant du même coup la boucle de synchronisation qui seule pourrait
/// réparer l'état. Toute lecture rend donc un nullable, et c'est l'appelant qui
/// décide ce que « inconnu » signifie chez lui.
///
/// Les permissions sont un **ensemble ouvert de chaînes** : le catalogue
/// serveur peut grandir sans release, donc aucune valeur n'est validée contre
/// une énumération — les inconnues sont conservées telles quelles.
///
/// Le stockage se fait en JSON plutôt qu'en chaîne jointe : l'ensemble étant
/// ouvert, aucun séparateur ne peut être garanti absent des valeurs futures.
abstract final class SessionPermissions {
  /// Ensemble vide — aucun droit. À ne pas confondre avec `null`.
  static const List<String> none = <String>[];

  /// Normalise une valeur brute issue du fil (`json['permissions']`).
  ///
  /// `null`, clé absente ou type inattendu rendent `null` : le serveur n'a rien
  /// dit d'exploitable, et prétendre le contraire écraserait un ensemble connu.
  /// Une liste, même vide, est prise au mot. Entrées non-chaînes, vides et
  /// doublons écartés sans erreur, espaces rognés, ordre d'émission préservé.
  static List<String>? sanitizeOrNull(Object? raw) {
    if (raw is! List) return null;
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
  /// L'ensemble vide s'écrit `[]`, donc se relit sans ambiguïté.
  static String encode(List<String> permissions) => jsonEncode(permissions);

  /// Relit une valeur stockée. Absente, vide ou corrompue rend `null` :
  /// « rien d'enregistré » et « enregistré vide » ne sont pas le même fait, et
  /// une donnée illisible ne prouve pas un retrait de droits.
  static List<String>? decodeOrNull(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return sanitizeOrNull(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }
}
