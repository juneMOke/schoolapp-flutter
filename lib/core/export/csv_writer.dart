/// Écriture CSV — le format « maison », en un seul endroit.
///
/// Le tableur de destination est Excel sur un poste francophone, et c'est lui
/// qui dicte les quatre choix ci-dessous. Aucun n'est négociable feuille par
/// feuille : deux exports au format différent, c'est un utilisateur qui apprend
/// que « ça s'ouvre bien depuis la Facturation, mal depuis les Inscriptions ».
///
/// * **BOM UTF-8** en tête — sans lui, Excel lit un fichier `Kinshasa` comme
///   `KinshasaÂ` et l'utilisateur conclut que l'application corrompt ses noms ;
/// * **point-virgule** en séparateur — la virgule est le séparateur décimal en
///   locale française, Excel casserait les colonnes sur le premier montant ;
/// * **CRLF** en fin de ligne ;
/// * **toutes** les cellules entre guillemets, guillemets internes doublés —
///   guillemeter au cas par cas oblige à décider, et la décision se trompe le
///   jour où une donnée contient un point-virgule.
///
/// Extrait de `FinanceCsvExportHelper`, qui l'a inauguré et qui délègue
/// désormais ici : le format était juste, il n'était simplement pas partageable.
abstract final class CsvWriter {
  /// BOM UTF-8 (U+FEFF) — assure une ouverture correcte dans Excel.
  static const String bom = '\u{FEFF}';

  /// Séparateur de colonnes.
  static const String separator = ';';

  /// Fin de ligne.
  static const String lineEnding = '\r\n';

  /// Document complet : BOM, puis une ligne par entrée de [rows].
  ///
  /// La première ligne n'a rien de spécial pour ce writer — passer l'en-tête en
  /// tête de [rows] suffit, et c'est ce qui permet à un export sans en-tête
  /// d'exister sans paramètre supplémentaire.
  static String document(Iterable<List<String>> rows) {
    final buffer = StringBuffer(bom);
    for (final cells in rows) {
      buffer.write(row(cells));
    }
    return buffer.toString();
  }

  /// Une ligne terminée par sa fin de ligne.
  static String row(List<String> values) =>
      values.map(escapeCell).join(separator) + lineEnding;

  /// Une cellule : espaces de bordure retirés, guillemets internes doublés,
  /// le tout entre guillemets.
  static String escapeCell(String value) {
    final normalized = value.replaceAll('"', '""').trim();
    return '"$normalized"';
  }

  /// Nom de fichier composé de [parts] slugifiées, séparées par des tirets.
  ///
  /// Les parties vides sont écartées : un libellé absent laisse un nom plus
  /// court, jamais un double tiret.
  static String fileName(List<String> parts, {String extension = 'csv'}) {
    final kept = parts.map(slugify).where((part) => part.isNotEmpty);
    return '${kept.join('-')}.$extension';
  }

  /// Slugifie une chaîne : minuscules, accents retirés, caractères non
  /// alphanumériques remplacés par des tirets (sans tirets en bordure).
  static String slugify(String value) {
    final lowered = removeDiacritics(value.trim().toLowerCase());
    final dashed = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return dashed.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Replie les accents français sur leur lettre de base.
  ///
  /// Table explicite plutôt que normalisation Unicode : `dart:core` n'expose
  /// pas NFD, et la table couvre l'intégralité des diacritiques qu'un nom ou un
  /// libellé de frais porte dans ce contexte.
  static String removeDiacritics(String value) {
    const withDiacritics = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const withoutDiacritics = 'aaaaaaceeeeiiiinooooouuuuyy';
    var result = value;
    for (var i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result;
  }
}
