/// Codes de refus du serveur pour le sujet, la copie et les publications
/// d'une évaluation — lus dans `ApiErrorResponse.detailCode`.
abstract final class EvaluationSujetCodes {
  /// Le maximum ne change plus : des notes `NOTEE` existent.
  static const String maxLocked = 'MAX_LOCKED';

  /// Un identifiant de question appartient déjà à une autre évaluation.
  static const String questionMismatch = 'QUESTION_MISMATCH';

  /// Un identifiant de ligne du journal existe déjà sous une autre évaluation.
  static const String copieLogMismatch = 'COPIE_LOG_MISMATCH';

  /// Sujet d'une interrogation ou d'un examen : il se fait en classe.
  static const String sujetNotPublishable = 'SUJET_NOT_PUBLISHABLE';

  /// Aucune question à publier.
  static const String sujetEmpty = 'SUJET_EMPTY';

  /// Un élève n'a pas de note, ou une note est en attente ; `details` porte
  /// `saisies` et `effectif`.
  static const String evaluationIncomplete = 'EVALUATION_INCOMPLETE';

  /// Le cours n'est pas celui de l'enseignant connecté.
  static const String coursNotOwned = 'COURS_NOT_OWNED';
}
