import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';

/// Ce qu'un geste réécrit sur la ligne de `expenses` — **et rien d'autre**.
///
/// Une mise à jour étroite, pour la raison qui vaut déjà pour
/// `ExpenseLocalModel.toLocalWriteMap` : un accusé ou un pull appliqué entre
/// la lecture de la demande et ce geste a pu poser un numéro, une version ou
/// un retrait. Réécrire la ligne entière depuis la lecture d'avant les
/// déferait.
///
/// ⚠️ Le compteur de relances n'est **pas** ici : l'incrémenter demande de
/// lire la colonne dans la même transaction (`reminder_count + 1`), ce qu'une
/// carte de colonnes ne sait pas exprimer. C'est
/// `ExpenseMessageDao.appendGesture` qui s'en charge, sur le drapeau
/// [ExpenseGesture.remind].
///
/// ⚠️ `status` et `paid_on` appartiennent à la **famille serveur** du delta
/// (`ExpenseDeltaColumns.server`, « toujours posée ») : tant que le pull ne
/// rapporte pas les six colonnes de décision — DEP-14 —, une décision prise
/// ici est écrasée au prochain pull par l'état que le serveur connaît encore.
/// C'est la face visible de « la décision est optimiste et restaurable »
/// (F22), et c'est l'une des raisons pour lesquelles la branche n'est pas
/// livrable avant que la remontée n'existe.
abstract final class ExpenseGestureColumns {
  static Map<String, Object?> of(
    ExpenseGesture gesture, {
    required String actorId,
    required String? actorName,
    required DateTime at,
    String? reason,
  }) {
    final target = gesture.target;
    if (target == null) return const {};
    return <String, Object?>{
      'status': target.wireValue,
      if (gesture.recordsDecider) ...{
        'decided_by_id': actorId,
        'decided_by_name': actorName,
        'decided_at': at.toUtc().toIso8601String(),
        // Seul un refus porte un motif ; une approbation qui en garderait un
        // ferait lire « accordée » au-dessus du texte d'un refus précédent.
        'decision_reason': gesture.requiresNote ? reason : null,
      },
      // Le paiement pose la date de règlement, et lui seul (F20) : c'est le
      // jour du décaissement, pas celui de la dépense ni celui de l'accord.
      if (gesture == ExpenseGesture.pay) 'paid_on': ExpenseDay.format(at),
      // Le retour en attente efface la décision, la date de règlement et le
      // compteur — jamais le fil : l'historique reste lisible, seule la
      // situation courante est réécrite.
      if (gesture.clearsDecision) ...{
        'decided_by_id': null,
        'decided_by_name': null,
        'decided_at': null,
        'decision_reason': null,
        'paid_on': null,
        'reminder_count': 0,
      },
    };
  }
}
