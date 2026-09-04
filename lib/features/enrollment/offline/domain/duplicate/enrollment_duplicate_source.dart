/// D'où vient l'élève que la sonde de doublon a retrouvé.
///
/// Ce n'est pas une nuance décorative : les deux sources ne disent pas la même
/// chose au guichet.
enum EnrollmentDuplicateSource {
  /// Un dossier de l'**année courante** — brouillon compris. « Cet enfant est
  /// déjà en cours d'inscription, ou déjà inscrit, cette année. »
  currentYearDossier,

  /// La **cohorte N-1** (`ref_previous_year_students`). « Cet enfant était
  /// élève l'an dernier » — donc il relève de la **Réinscription**, pas d'une
  /// Première inscription. C'est le doublon que le terrain fabrique vraiment.
  previousYearCohort,
}
