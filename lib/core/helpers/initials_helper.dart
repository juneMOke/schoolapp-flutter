/// Helper pur pour le calcul des initiales d'un élève.
///
/// Deux entrées publiques :
/// - [InitialsHelper.initialsFrom]     : cas standard StudentAvatar (firstName + lastName)
/// - [InitialsHelper.initialsFromName] : cas d'un nom composé unique (apostrophe / tiret)
class InitialsHelper {
  InitialsHelper._();

  // ---------------------------------------------------------------------------
  // API publique
  // ---------------------------------------------------------------------------

  /// Retourne 2 initiales à partir de [firstName] et [lastName].
  ///
  /// Règles :
  /// - Si [lastName] n'est pas vide → premier char de [lastName] + premier char de [firstName]
  ///   (ordre NOM-Prénom, convention RDC).
  /// - Si [lastName] est vide → premier char de [firstName] doublé (ex. "JJ").
  /// - Toujours en majuscules, accents normalisés.
  /// - Retourne "?" si les deux champs sont vides.
  static String initialsFrom(String firstName, String lastName) {
    final lastChar = _firstAlphaChar(lastName);
    final firstChar = _firstAlphaChar(firstName);

    if (lastChar.isNotEmpty) {
      return (_normalize(lastChar) + _normalize(firstChar)).toUpperCase();
    }

    if (firstChar.isNotEmpty) {
      final c = _normalize(firstChar).toUpperCase();
      return '$c$c';
    }

    return '?';
  }

  /// Retourne 1 à 2 initiales à partir d'un nom unique potentiellement composé.
  ///
  /// Les apostrophes et tirets sont traités comme separateurs de segments.
  ///
  /// Exemples :
  /// - "N'Sumbu"        → "NS"
  /// - "Ndombo-Kabongo" → "NK"
  /// - "Marie-Claire"   → "MC"
  /// - "Jean"           → "J"
  static String initialsFromName(String name) {
    if (name.trim().isEmpty) return '';

    final segments = name
        .split(RegExp(r"['\-]"))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final chars = segments
        .map(_firstAlphaChar)
        .where((c) => c.isNotEmpty)
        .take(2)
        .map(_normalize)
        .join()
        .toUpperCase();

    return chars;
  }

  // ---------------------------------------------------------------------------
  // Helpers privés
  // ---------------------------------------------------------------------------

  static String _firstAlphaChar(String name) {
    for (final rune in name.runes) {
      final char = String.fromCharCode(rune);
      if (_isLetter(char)) return char;
    }
    return '';
  }

  static bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    // ASCII a-z / A-Z
    if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) return true;
    // Latin extended (lettres accentuées courantes)
    if (code >= 0xC0 && code <= 0x2AF) return true;
    return false;
  }

  static String _normalize(String char) {
    const accentMap = {
      'à': 'A',
      'á': 'A',
      'â': 'A',
      'ã': 'A',
      'ä': 'A',
      'å': 'A',
      'æ': 'A',
      'ç': 'C',
      'è': 'E',
      'é': 'E',
      'ê': 'E',
      'ë': 'E',
      'ì': 'I',
      'í': 'I',
      'î': 'I',
      'ï': 'I',
      'ð': 'D',
      'ñ': 'N',
      'ò': 'O',
      'ó': 'O',
      'ô': 'O',
      'õ': 'O',
      'ö': 'O',
      'ù': 'U',
      'ú': 'U',
      'û': 'U',
      'ü': 'U',
      'ý': 'Y',
      'ÿ': 'Y',
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'Å': 'A',
      'Æ': 'A',
      'Ç': 'C',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ð': 'D',
      'Ñ': 'N',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ý': 'Y',
    };
    return accentMap[char] ?? char;
  }
}
