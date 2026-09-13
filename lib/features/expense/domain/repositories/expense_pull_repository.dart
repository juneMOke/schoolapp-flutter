import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_pull_outcome.dart';

/// Nom de ressource du flux du registre — la « ressource cliente » que le
/// catalogue serveur déclare pour `expense.expenses`, et l'identité du
/// `PullHandler` devant le coordinateur et le plan (`kSyncPlanAliases`).
const String kExpensesResource = 'expenses';

/// Descente du registre des dépenses (`expense.expenses`).
abstract class ExpensePullRepository {
  Future<Either<Failure, ExpensePullOutcome>> syncExpenses();
}
