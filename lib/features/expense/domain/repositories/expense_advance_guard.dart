/// Ce que la Paie dit d'une dépense d'avance au personnel (B6) — un port,
/// implémenté par le module Paie : les Dépenses n'ont pas à lire les paies.
abstract class ExpenseAdvanceGuard {
  /// Une retenue est-elle déjà figée sur une paie validée ? Dès lors, la
  /// dépense ne se rouvre plus : l'argent est en train de revenir.
  Future<bool> isDeducted(String expenseId);

  /// La paie de [month] (`YYYY-MM`) peut-elle encore recevoir une première
  /// retenue — absente ou en brouillon ?
  Future<bool> acceptsFirstMonth(String month);
}
