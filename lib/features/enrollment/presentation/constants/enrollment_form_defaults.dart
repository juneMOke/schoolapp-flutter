/// Défauts MÉTIER du formulaire d'inscription : valeurs de données persistées
/// telles quelles (pas des libellés UI → hors AppLocalizations, comme
/// `NationalityCatalog.defaultNationality`).
class EnrollmentFormDefaults {
  const EnrollmentFormDefaults._();

  /// Lieu de naissance pré-rempli pour un nouveau dossier dont le champ est
  /// vide (cas majoritaire des élèves de l'école). Jamais appliqué en
  /// consultation ni par-dessus une valeur déjà saisie/seedée.
  static const String birthPlace = 'Kinshasa';
}
