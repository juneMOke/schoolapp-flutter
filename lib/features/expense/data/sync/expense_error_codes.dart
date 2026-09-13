/// Codes machine (`detailCode`) des refus du registre des dépenses
/// (`ExpenseErrorCodes` côté serveur).
///
/// **Aucun n'est récupérable par un rejeu** : la dépense se corrige sur le
/// poste (A4 — la ligne porte son motif). C'est pourquoi le handler les classe
/// tous en échec terminal plutôt qu'en tentative.
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
}
