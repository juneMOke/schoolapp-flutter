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

  /// **422** — on n'approuvait pas sa propre demande (A11). Abandonné le
  /// 2026-09-25 : le serveur ne l'émet plus. Gardé en lecture, le
  /// reconnaître ne coûte rien.
  static const String selfApprovalForbidden = 'SELF_APPROVAL_FORBIDDEN';

  /// **403** — le geste est réservé au demandeur (retirer, renvoyer,
  /// relancer, modifier le contenu).
  static const String notRequestOwner = 'NOT_REQUEST_OWNER';

  // ── Avance au personnel (Paie v2, B5-B7) ────────────────────────────────

  /// **403** — déposer ou modifier une avance sans `hr.pay.read` : on ne
  /// remplit pas un bloc R.H. qu'on ne voit pas.
  static const String staffAdvanceForbidden = 'STAFF_ADVANCE_FORBIDDEN';

  /// **422** — une avance sans bloc R.H., ou payée sans `advance`.
  static const String staffAdvanceDetailsRequired =
      'STAFF_ADVANCE_DETAILS_REQUIRED';

  /// **422** — nature et échéances en désaccord, ou première retenue sur un
  /// mois passé.
  static const String invalidStaffAdvance = 'INVALID_STAFF_ADVANCE';

  /// **422** — une avance accordée ou payée ne se modifie plus.
  static const String staffAdvanceLocked = 'STAFF_ADVANCE_LOCKED';

  /// **422** — une avance payée ne se retire ni ne se supprime.
  static const String staffAdvancePaid = 'STAFF_ADVANCE_PAID';

  /// **409** — l'agent de l'avance n'est pas encore remonté : une attente,
  /// rejouée, jamais un refus.
  static const String staffMemberNotYetSynced = 'STAFF_MEMBER_NOT_YET_SYNCED';

  // Les gardes de la Paie, atteintes par le PAY ou la réouverture d'une
  // avance : des refus du geste, jamais du contenu.
  static const String advanceMonthLocked = 'ADVANCE_MONTH_LOCKED';
  static const String advanceAlreadyDeducted = 'ADVANCE_ALREADY_DEDUCTED';
  static const String signatureRequired = 'SIGNATURE_REQUIRED';
  static const String invalidAdvance = 'INVALID_ADVANCE';
  static const String advanceCurrencyMismatch = 'ADVANCE_CURRENCY_MISMATCH';
  static const String staffNotOnPayroll = 'STAFF_NOT_ON_PAYROLL';

  /// Les refus qui viennent d'un **geste**, et non d'une saisie.
  ///
  /// La distinction se paie à deux endroits : l'écran ne conseille pas de
  /// corriger une dépense à laquelle il n'y a rien à corriger, et un geste
  /// réussi lève le « à corriger » qu'un geste précédent avait posé — là où
  /// un refus de CONTENU attend, lui, une vraie correction.
  static const Set<String> gestureRefusals = {
    decisionAlreadyTaken,
    transitionOutOfOrder,
    reasonRequired,
    selfApprovalForbidden,
    notRequestOwner,
    staffAdvancePaid,
    staffAdvanceDetailsRequired,
    invalidStaffAdvance,
    advanceMonthLocked,
    advanceAlreadyDeducted,
    signatureRequired,
    invalidAdvance,
    advanceCurrencyMismatch,
    staffNotOnPayroll,
  };
}
