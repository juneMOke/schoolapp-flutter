/// Découpage de l'année d'un cycle : trimestres ou semestres.
///
/// Déterminé par le `periodType` du groupe de niveaux (cycle) dans le bootstrap :
/// une classe donnée est **toujours** rattachée à un seul découpage. Le parseur
/// est tolérant (variantes FR/EN, casse), repli [Decoupage.unknown].
enum Decoupage { trimestre, semestre, unknown }

extension DecoupageX on Decoupage {
  /// Interprète un `periodType` brut (`TRIMESTRE`, `SEMESTER`, `Trimestriel`…).
  ///
  /// Tolérant : on cherche la racine `TRI` / `SEM` en majuscules ; tout le reste
  /// (`null`, `YEAR`, `ANNUAL`, valeur inconnue) donne [Decoupage.unknown].
  static Decoupage fromApiValue(String? value) {
    final normalized = value?.toUpperCase().trim() ?? '';
    if (normalized.contains('TRI')) {
      return Decoupage.trimestre;
    }
    if (normalized.contains('SEM')) {
      return Decoupage.semestre;
    }
    return Decoupage.unknown;
  }
}
