import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';

// Les quatre gestes d'écriture du registre. Chacun réussit localement d'abord ;
// le serveur tranche plus tard, dans l'accusé (A4).

/// Créer, modifier ou dupliquer.
class SaveExpenseUseCase {
  final ExpenseRepository _repository;

  const SaveExpenseUseCase(this._repository);

  Future<Either<Failure, Expense>> call(ExpenseDraft draft) =>
      _repository.save(draft);
}

/// Marquer payée / repasser en non payée, sans formulaire.
class SetExpenseStatusUseCase {
  final ExpenseRepository _repository;

  const SetExpenseStatusUseCase(this._repository);

  Future<Either<Failure, Expense>> call(
    Expense expense,
    ExpenseStatus status,
  ) => _repository.setStatus(expense, status);
}

/// Retirer du registre (D4).
class WithdrawExpenseUseCase {
  final ExpenseRepository _repository;

  const WithdrawExpenseUseCase(this._repository);

  Future<Either<Failure, Unit>> call(Expense expense) =>
      _repository.withdraw(expense);
}

/// Restaurer — le « Annuler » du toast.
class RestoreExpenseUseCase {
  final ExpenseRepository _repository;

  const RestoreExpenseUseCase(this._repository);

  Future<Either<Failure, Unit>> call(Expense expense) =>
      _repository.restore(expense);
}
