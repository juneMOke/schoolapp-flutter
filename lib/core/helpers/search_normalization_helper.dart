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

  /// `true` si **au moins une** paire (valeur, critère) se correspond.
  ///
  /// C'est le « OU » de la recherche par identité : quelqu'un se retrouve par
  /// son nom, son post-nom **ou** son prénom, sans qu'il faille les connaître
  /// tous les trois. Deux critères remplis élargissent donc le résultat au lieu
  /// de le restreindre — c'est le prix assumé du OU.
  ///
  /// Aucun critère renseigné ⇒ `true` : un filtre sans critère ne retire
  /// personne. Sans cette garde, le OU viderait toute liste ouverte sans
  /// recherche (un `any` sur zéro critère est faux), là où l'ancien ET la
  /// laissait entière.
  static bool containsAny(Iterable<(String? value, String? term)> pairs) {
    var hasCriterion = false;
    for (final (value, term) in pairs) {
      if ((term?.trim() ?? '').isEmpty) continue;
      hasCriterion = true;
      if (contains(value, term)) return true;
    }
    return !hasCriterion;
  }
}
