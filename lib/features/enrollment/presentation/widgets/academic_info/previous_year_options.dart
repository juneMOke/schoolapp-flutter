/// Les années scolaires proposées au bloc « scolarité antérieure ».
///
/// **Ancrées sur l'année scolaire de l'ÉCOLE**, pas sur l'horloge de
/// l'appareil. De janvier à août, `DateTime.now().year` désigne le millésime de
/// FIN de l'année en cours : la liste proposait alors l'année courante en tête,
/// donc comme « année précédente ». Tant que rien n'était présélectionné cela
/// restait une bizarrerie de la liste ; dès qu'on préremplit, ce serait une
/// réponse fausse écrite dans le dossier.
class PreviousYearOptions {
  const PreviousYearOptions._();

  /// Profondeur de la liste, la plus récente d'abord.
  static const int depth = 3;

  /// Les [depth] années scolaires qui précèdent celle de l'école.
  ///
  /// [currentAcademicYearName] est le libellé de l'année courante
  /// (« 2026-2027 ») ; illisible ou absent, on retombe sur l'horloge — le
  /// comportement historique, qui reste juste pendant la saison d'inscription.
  static List<String> build({String? currentAcademicYearName}) {
    final start = startYearOf(currentAcademicYearName) ?? DateTime.now().year;
    return List<String>.unmodifiable([
      for (var offset = 1; offset <= depth; offset++)
        '${start - offset}-${start - offset + 1}',
    ]);
  }

  /// L'année scolaire qui précède immédiatement celle de l'école — la valeur
  /// proposée d'office au guichet, qui inscrit presque toujours un enfant
  /// venant de l'année qui vient de s'achever.
  static String previousOf({String? currentAcademicYearName}) =>
      build(currentAcademicYearName: currentAcademicYearName).first;

  /// Millésime de DÉBUT porté par un libellé d'année scolaire (« 2026-2027 »
  /// → 2026), ou `null` si le libellé ne se laisse pas lire.
  static int? startYearOf(String? name) {
    if (name == null) return null;
    final match = RegExp(r'(\d{4})').firstMatch(name);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Résout [rawYear] parmi [options] en comparaison normalisée (ignore espaces
  /// et tirets multiples).
  ///
  /// **Rend `null` quand le dossier ne dit rien** : le repli éventuel est une
  /// décision de l'écran, pas de la résolution. Un libellé illisible est
  /// conservé tel quel plutôt que remplacé — il vient d'une vraie saisie, et le
  /// premier élément du catalogue serait une réponse inventée à sa place.
  static String? resolve(String? rawYear, List<String> options) {
    if (rawYear == null || rawYear.trim().isEmpty) return null;

    final candidate = normalizeKey(rawYear);
    for (final option in options) {
      if (normalizeKey(option) == candidate) return option;
    }
    return rawYear.trim();
  }

  static String normalizeKey(String value) =>
      value.replaceAll(RegExp(r'[\s\-–]+'), '-').trim();
}
