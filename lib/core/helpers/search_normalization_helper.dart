/// Helper pur pour la recherche insensible à la casse et aux accents.
///
/// Utilisé partout où l'on filtre par nom/prénom/postnom côté client
/// (ex. listings d'inscription offline) afin que "jose" trouve "José"
/// et que "Ecole" trouve "École".
class SearchNormalizationHelper {
  SearchNormalizationHelper._();

  static const _accented = 'àáâãäåæçèéêëìíîïðñòóôõöùúûüýÿ';
  static const _plain = 'aaaaaaaceeeeiiiidnooooouuuuyy';

  /// Normalise [value] : minuscules + accents retirés.
  static String normalize(String value) {
    final lowered = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lowered.runes) {
      final char = String.fromCharCode(rune);
      final index = _accented.indexOf(char);
      buffer.write(index == -1 ? char : _plain[index]);
    }
    return buffer.toString();
  }

  /// `true` si [field] contient [term], insensible à la casse et aux accents.
  /// [term] vide (ou null) matche toujours.
  static bool contains(String? field, String? term) {
    final normalizedTerm = normalize(term?.trim() ?? '');
    if (normalizedTerm.isEmpty) return true;
    return normalize(field ?? '').contains(normalizedTerm);
  }
}
