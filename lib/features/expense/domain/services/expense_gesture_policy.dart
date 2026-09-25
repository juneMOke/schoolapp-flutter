import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_transitions.dart';

/// Ce que l'**état** de la demande et la **propriété** autorisent — deux des
/// trois filtres de F29. Le troisième, la permission, se croise par-dessus, à
/// l'écran, par `PermissionGate.access` : il n'a pas sa place dans le domaine,
/// qui ne connaît pas la session.
///
/// Les trois sont des ET, jamais des OU. Un geste offert alors qu'il est voué
/// à l'échec ne fabrique pas une erreur rattrapable : il fabrique une entrée
/// d'outbox morte — 403 comme 422 sont terminaux dans notre classement — et
/// une ligne « à corriger » que son auteur ne peut pas corriger.
abstract final class ExpenseGesturePolicy {
  /// Le geste peut-il être **offert** sur cette demande, au compte
  /// [accountId] ?
  static bool allows(
    ExpenseGesture gesture,
    Expense expense, {
    String? accountId,
  }) {
    // Retirée du registre, une demande ne se décide plus : le serveur n'a
    // plus rien à trancher, et le geste attendrait un état qui ne reviendra
    // pas. La restaurer la remet dans le circuit telle qu'elle était.
    if (expense.isWithdrawn) return false;
    if (!_ownershipAllows(gesture, expense, accountId)) return false;
    return _statusAllows(gesture, expense.status);
  }

  static bool _ownershipAllows(
    ExpenseGesture gesture,
    Expense expense,
    String? accountId,
  ) => switch (gesture.ownership) {
    ExpenseGestureOwnership.anyone => true,
    ExpenseGestureOwnership.requesterOnly => expense.isRequestedBy(accountId),
  };

  /// Toute réponse vient de [ExpenseTransitions] — la table est la seule
  /// source, et aucune paire qui lui est absente ne doit être atteignable.
  static bool _statusAllows(ExpenseGesture gesture, ExpenseStatus from) =>
      switch (gesture) {
        ExpenseGesture.approve ||
        ExpenseGesture.refuse => ExpenseTransitions.canDecide(from),
        ExpenseGesture.pay => ExpenseTransitions.canPay(from),
        ExpenseGesture.resubmit => ExpenseTransitions.canResubmit(from),
        ExpenseGesture.reopen => ExpenseTransitions.canReopen(from),
        // Retirer sa demande et la relancer visent la même fenêtre : tant
        // qu'elle attend. Une fois tranchée, relancer n'a plus d'objet et
        // reprendre passe par la correction.
        ExpenseGesture.retract => ExpenseTransitions.isAllowed(
          from,
          ExpenseStatus.retracted,
        ),
        ExpenseGesture.remind => from == ExpenseStatus.pending,
        // Commenter n'est pas une transition : le fil reste ouvert à tous les
        // états, y compris une demande refusée que l'on veut comprendre.
        ExpenseGesture.comment => true,
      };

  /// Les gestes offrables sur cette demande, dans l'ordre de l'énumération —
  /// l'écran y ajoute la permission et n'a donc jamais à rejouer cette règle.
  static List<ExpenseGesture> offeredOn(Expense expense, {String? accountId}) =>
      [
        for (final gesture in ExpenseGesture.values)
          if (allows(gesture, expense, accountId: accountId)) gesture,
      ];
}
