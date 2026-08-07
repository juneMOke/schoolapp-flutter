/// Ramène un texte au jeu de caractères qu'un ticket sait réellement porter.
///
/// ## Pourquoi ce passage est obligatoire
///
/// Le rendu PDF utilise `courier`, une police base-14 Type1 encodée en WinAnsi
/// (Latin-1). Le paquet `pdf` ne lève pas sur un caractère qu'elle ne couvre
/// pas : il journalise et **supprime le glyphe**. « Institut Sacré-Cœur »
/// s'imprimait « Institut Sacré-Cur », et l'apostrophe typographique `’` —
/// celle que produisent les claviers mobiles et les copier-coller — disparaissait
/// purement et simplement. Sur une pièce remise à un parent, une perte
/// silencieuse est le pire des comportements.
///
/// La sortie ESC/POS aura la même contrainte, en pire (pages de code
/// mono-octet) : ce module est donc partagé, pas propre au PDF.
///
/// ## Deux garanties
///
/// 1. **Rien ne disparaît sans le dire.** Ce qui a une translittération connue
///    est translittéré ; tout le reste devient [replacement], visible.
/// 2. **Appelé AVANT tout calcul de largeur.** `œ` → `oe` gagne un caractère :
///    translittérer après la mise en colonnes décalerait l'alignement du
///    gabarit à 48 colonnes.
abstract final class TicketCharset {
  /// Marque d'un caractère sans translittération connue. Visible à dessein : un
  /// nom imprimé « M?ller » se corrige, un nom imprimé « Mller » se croit juste.
  static const String replacement = '?';

  /// Translittérations qui ne tiennent pas sur un seul caractère, ou qui ne
  /// sont pas de simples lettres accentuées.
  static const Map<int, String> _explicit = {
    // Ligatures.
    0x0152: 'OE', 0x0153: 'oe', 0x0132: 'IJ', 0x0133: 'ij',
    0xFB00: 'ff', 0xFB01: 'fi', 0xFB02: 'fl', 0xFB03: 'ffi', 0xFB04: 'ffl',
    // Ponctuation typographique — le gros du volume réel.
    0x2018: "'", 0x2019: "'", 0x201A: "'", 0x201B: "'",
    0x201C: '"', 0x201D: '"', 0x201E: '"', 0x201F: '"',
    0x2010: '-', 0x2011: '-', 0x2012: '-', 0x2013: '-', 0x2014: '-',
    0x2015: '-', 0x2212: '-',
    0x2026: '...', 0x2022: '*', 0x2027: '.',
    0x2039: '<', 0x203A: '>', 0x2032: "'", 0x2033: '"',
    0x2030: '%o', 0x2116: 'No', 0x2122: '(TM)', 0x20AC: 'EUR',
    // Espaces exotiques : ramenées à l'espace, sinon la mise en colonnes les
    // traiterait comme des caractères pleins. (L'espace insécable `U+00A0`, elle,
    // appartient déjà au Latin-1 et passe par la voie directe.)
    0x2007: ' ', 0x2009: ' ', 0x200A: ' ', 0x202F: ' ',
    0x2002: ' ', 0x2003: ' ', 0x2004: ' ', 0x2005: ' ', 0x2006: ' ',
    // Largeur nulle : rien à imprimer, et un `?` serait faux.
    0x200B: '', 0x200C: '', 0x200D: '', 0xFEFF: '',
    // Latin étendu B des orthographes d'Afrique centrale (lingala, tshiluba,
    // kikongo) : ces lettres apparaissent dans des noms propres.
    0x0190: 'E', 0x025B: 'e', 0x0186: 'O', 0x0254: 'o',
    0x0181: 'B', 0x0253: 'b', 0x018A: 'D', 0x0257: 'd',
    0x0194: 'G', 0x0263: 'g', 0x01A9: 'S', 0x0283: 's',
    // Carons de notation tonale.
    0x01CD: 'A', 0x01CE: 'a', 0x01CF: 'I', 0x01D0: 'i',
    0x01D1: 'O', 0x01D2: 'o', 0x01D3: 'U', 0x01D4: 'u',
    0x01F4: 'G', 0x01F5: 'g', 0x01F8: 'N', 0x01F9: 'n',
  };

  /// Lettre de base de chaque point de code du latin étendu A
  /// (`U+0100`–`U+017F`), dans l'ordre. Les quatre entrées à deux caractères
  /// (`Ĳ ĳ Œ œ`) sont traitées par [_explicit] et portent ici un marqueur.
  static const String _latinExtendedA =
      'AaAaAaCcCcCcCcDd'
      'DdEeEeEeEeEeGgGg'
      'GgGgHhHhIiIiIiIi'
      'Ii??JjKkkLlLlLlL'
      'lLlNnNnNnnNnOoOo'
      'Oo??RrRrRrSsSsSs'
      'SsTtTtTtUuUuUuUu'
      'UuUuWwYyYZzZzZzs';

  /// Vrai si [text] est déjà intégralement imprimable.
  static bool isPrintable(String text) =>
      text.runes.every((rune) => rune <= 0xFF);

  /// Rend [text] imprimable. Idempotent.
  static String printable(String text) {
    if (isPrintable(text)) return text;

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune <= 0xFF) {
        buffer.writeCharCode(rune);
        continue;
      }

      final explicit = _explicit[rune];
      if (explicit != null) {
        buffer.write(explicit);
        continue;
      }

      if (rune >= 0x0100 && rune <= 0x017F) {
        final base = _latinExtendedA[rune - 0x0100];
        buffer.write(base == '?' ? replacement : base);
        continue;
      }

      buffer.write(replacement);
    }

    return buffer.toString();
  }
}
