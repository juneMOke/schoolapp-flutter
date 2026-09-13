import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_pull_repository.dart';

/// [PullHandler] du registre des dépenses, enregistré sur le
/// `PullCoordinator`. Ne lève pas : un `Left` devient un [PullOutcome.error].
///
/// `expense.read` seul : c'est la permission qui ouvre le menu, et le flux
/// n'est jamais entraîné par un autre module.
class ExpensePullHandler implements PullHandler {
  final ExpensePullRepository _repository;

  const ExpensePullHandler(this._repository);

  @override
  String get resource => kExpensesResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.expenseRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncExpenses();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
