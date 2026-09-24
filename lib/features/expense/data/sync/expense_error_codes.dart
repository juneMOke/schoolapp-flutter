/// Codes machine (`detailCode`) des refus du registre des dépenses
/// (`ExpenseErrorCodes` côté serveur).
///
/// Ceux de la **V1** ne sont récupérables par aucun rejeu : la dépense se
/// corrige sur le poste (A4 — la ligne porte son motif). Ceux du **circuit**
/// se lisent un par un : deux 409 y portent des conduites opposées (F34).
abstract final class ExpenseErrorCodes {
  /// Le type désigné n'existe pas pour cette école.
  static const String unknownExpenseType = 'UNKNOWN_EXPENSE_TYPE';

  /// La date de la dépense dépasse demain, dans le fuseau de l'école.
  static const String expenseDateInFuture = 'EXPENSE_DATE_IN_FUTURE';

  /// La date de règlement dépasse demain, dans le fuseau de l'école.
  static const String paymentDateInFuture = 'PAYMENT_DATE_IN_FUTURE';

  /// Dépense purgée physiquement côté serveur (410) : le poste efface sa
  /// ligne au lieu de la rejouer.
  static const String aggregateTombstoned = 'AGGREGATE_TOMBSTONED';

  // ── Circuit de validation (v2) ──────────────────────────────────────────

  /// **409** — un collègue a tranché avant nous.
  ///
  /// Le poste se **réaligne** sur l'état canonique renvoyé, fil compris, et
  /// nomme le décideur. Il ne rejoue **jamais** : rejouer réécrirait la
  /// décision d'un autre.
  static const String decisionAlreadyTaken = 'DECISION_ALREADY_TAKEN';

  /// **409** — le geste est arrivé avant son prédécesseur.
  ///
  /// Conduite **exactement inverse** de la précédente : le poste **rejoue**,
  /// et ne réaligne rien — sa ligne est juste, c'est le serveur qui n'a pas
  /// encore vu ce qui vient avant. Le serveur ne peut pas distinguer un geste
  /// hors séquence d'un geste impossible (Q10), donc il n'oppose plus de 422
  /// sur les routes de geste.
  static const String transitionOutOfOrder = 'TRANSITION_OUT_OF_ORDER';

  /// **422** — un refus sans motif laisse le demandeur sans issue.
  static const String reasonRequired = 'REASON_REQUIRED';

  /// **422** — on n'approuve pas sa propre demande (A11, tranché par la
  /// direction, sans réglage d'école).
  static const String selfApprovalForbidden = 'SELF_APPROVAL_FORBIDDEN';

  /// **403** — le geste est réservé au demandeur (retirer, renvoyer,
  /// relancer, modifier le contenu).
  static const String notRequestOwner = 'NOT_REQUEST_OWNER';
}
