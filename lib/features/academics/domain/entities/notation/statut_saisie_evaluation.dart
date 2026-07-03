/// Statut de saisie dérivé d'une évaluation, calculé à partir des notes des
/// élèves :
/// - [nonSaisie] : rien ou partiellement saisi ;
/// - [enAttente] : au moins une note en attente ;
/// - [complete] : toutes les notes saisies.
///
/// `unknown` est un repli de résilience pour toute valeur backend absente ou
/// inconnue.
enum StatutSaisieEvaluation { nonSaisie, enAttente, complete, unknown }

extension StatutSaisieEvaluationX on StatutSaisieEvaluation {
  static StatutSaisieEvaluation fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'NON_SAISIE' => StatutSaisieEvaluation.nonSaisie,
        'EN_ATTENTE' => StatutSaisieEvaluation.enAttente,
        'COMPLETE' => StatutSaisieEvaluation.complete,
        _ => StatutSaisieEvaluation.unknown,
      };

  String toApiValue() => switch (this) {
    StatutSaisieEvaluation.nonSaisie => 'NON_SAISIE',
    StatutSaisieEvaluation.enAttente => 'EN_ATTENTE',
    StatutSaisieEvaluation.complete => 'COMPLETE',
    StatutSaisieEvaluation.unknown => 'UNKNOWN',
  };
}
