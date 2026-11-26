import 'package:school_app_flutter/core/money/cash_closure_reader.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_transitions.dart';

/// Peut-on encore **annuler** une déclaration sans ajustement de caisse
/// (F44) ? Une règle d'écran : le serveur reste le filet
/// (`CASH_DAY_ALREADY_CLOSED`), mais un geste offert pour mourir en 422
/// laisserait une entrée morte dans la file.
///
/// L'erreur ne va que dans le sens prudent : « Annuler » caché à tort,
/// jamais montré à tort (Q6).
class ExpenseDeclarationCancellation {
  /// `null` : la Trésorerie n'est pas montée (tests, module absent) — rien
  /// n'est retenu, comme ailleurs pour le verrou de caisse.
  final CashClosureReader? _closures;

  const ExpenseDeclarationCancellation(this._closures);

  /// `false` aussi bien pour ce qui n'est pas une déclaration en vigueur que
  /// pour une journée de caisse figée.
  Future<bool> canCancel(Expense expense) async {
    if (!expense.isDeclaration) return false;
    if (!ExpenseTransitions.canCancelDeclaration(expense.status)) return false;
    // Sans caisse dans la devise, rien n'est figé.
    if (expense.fundingSource != ExpenseFundingSource.cash) return true;
    // Arrivée après une clôture : la caissière a une réponse à donner, ou
    // l'a déjà donnée — la tablette ne sait pas laquelle (Q6, option b).
    if (expense.afterClosure) return false;
    final day = expense.cashDay;
    // Pas encore de ligne de caisse : la déclaration n'est pas accusée.
    // L'annulation attendra son tour derrière elle (F38), et le serveur
    // jugera.
    if (day == null) return true;
    final closures = _closures;
    if (closures == null) return true;
    try {
      return !await closures.hasLiveClosureFrom(day, expense.currency);
    } catch (_) {
      // Une lecture ratée ne doit pas offrir un geste qu'on ne sait pas
      // juger : le sens prudent.
      return false;
    }
  }
}
