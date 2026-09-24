import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// À qui un geste appartient — la seule règle du circuit qui ne se lit ni
/// dans le statut ni dans les permissions.
///
/// La propriété se juge sur l'identifiant, **jamais sur le nom** (F24) : deux
/// homonymes dans une école suffisent à donner le dernier mot au mauvais
/// compte.
enum ExpenseGestureOwnership {
  /// Le demandeur, et lui seul : relancer, retirer, corriger et renvoyer.
  /// Une propriété qu'on ne sait pas établir vaut « pas la sienne », donc le
  /// geste n'est pas offert.
  requesterOnly,

  /// Tout le monde **sauf** le demandeur — l'auto-approbation est refusée par
  /// la direction (A11), et le serveur la sanctionne d'un
  /// `422 SELF_APPROVAL_FORBIDDEN`. Une propriété indécidable laisse le geste
  /// offert : le masquer bloquerait une approbation légitime sans recours,
  /// alors qu'une approbation de trop est rattrapable par le serveur.
  othersOnly,

  /// Payer, annuler une décision, commenter : la propriété n'y entre pas.
  /// Commenter la demande d'un collègue est même tout l'objet de la route
  /// dédiée (Q1) — elle est sous `expense.write`, sans contrôle de propriété.
  anyone,
}

/// Les huit gestes du circuit de validation, tels qu'ils s'offrent à l'écran.
///
/// Sept routes serveur les portent — `decision` en sert deux, accorder et
/// refuser. Chacun écrit **un** message de fil, et c'est l'uuid de ce message
/// qui sert de clé d'idempotence au geste comme au message (Q3) : un rejeu
/// est inerte, et une relance ne compte jamais double.
///
/// Le statut n'est jamais saisi (D8) : il est le **résultat** d'un geste. Ce
/// que chaque geste vise est donc déclaré ici, une fois, plutôt que reconstruit
/// à chaque appel.
enum ExpenseGesture {
  approve(
    act: ExpenseAct.approval,
    target: ExpenseStatus.approved,
    ownership: ExpenseGestureOwnership.othersOnly,
  ),
  refuse(
    act: ExpenseAct.refusal,
    target: ExpenseStatus.refused,
    ownership: ExpenseGestureOwnership.othersOnly,
  ),
  pay(act: ExpenseAct.payment, target: ExpenseStatus.paid),

  /// Le demandeur reprend sa demande. Ce n'est **pas** une suppression : la
  /// demande reste au registre, réengageable par [resubmit].
  retract(
    act: ExpenseAct.retraction,
    target: ExpenseStatus.retracted,
    ownership: ExpenseGestureOwnership.requesterOnly,
  ),

  /// Corriger et renvoyer — côté serveur c'est **deux** gestes dans l'ordre,
  /// le contenu puis le renvoi (F32). Côté poste, seul le renvoi transitionne.
  resubmit(
    act: ExpenseAct.correction,
    target: ExpenseStatus.pending,
    ownership: ExpenseGestureOwnership.requesterOnly,
  ),

  /// La direction défait sa décision. Le seul geste du circuit qui revienne
  /// en arrière, et le filet qui rend toutes les autres décisions réparables.
  reopen(act: ExpenseAct.reopening, target: ExpenseStatus.pending),

  /// Le demandeur pousse : le compteur monte d'un, la demande ne bouge pas.
  remind(
    act: ExpenseAct.reminder,
    ownership: ExpenseGestureOwnership.requesterOnly,
  ),

  /// Le commentaire libre — le seul message du fil qui ne constate aucun
  /// geste, d'où son acte `null`.
  comment();

  const ExpenseGesture({
    this.act,
    this.target,
    this.ownership = ExpenseGestureOwnership.anyone,
  });

  /// L'acte écrit au fil ; `null` pour le commentaire libre.
  final ExpenseAct? act;

  /// Où le geste mène la demande, ou `null` quand il ne la déplace pas :
  /// relancer et commenter la laissent exactement où elle est.
  final ExpenseStatus? target;

  final ExpenseGestureOwnership ownership;

  /// Un geste sans cible ne passe pas par la table des transitions.
  bool get movesStatus => target != null;

  /// Un refus sans motif laisse le demandeur sans issue : l'écran l'interdit,
  /// et le serveur aussi (`422 REASON_REQUIRED`).
  bool get requiresNote => this == ExpenseGesture.refuse;

  /// Le retour en attente efface la décision, la date de règlement et le
  /// compteur de relances — mais jamais le fil.
  bool get clearsDecision => target == ExpenseStatus.pending;

  /// Poser le décideur sur la ligne, c'est **décider**. Payer ne décide pas :
  /// l'approbation garde son auteur, et l'écran continue d'afficher qui a
  /// accordé, pas qui a décaissé.
  bool get recordsDecider =>
      this == ExpenseGesture.approve || this == ExpenseGesture.refuse;
}
