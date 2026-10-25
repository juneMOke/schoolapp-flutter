import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';

/// Relit une demande sur la tablette, ou `null` si elle n'y est plus.
class FindExpenseUseCase {
  final ExpenseRepository _repository;

  const FindExpenseUseCase(this._repository);

  Future<Either<Failure, Expense?>> call(String expenseId) =>
      _repository.find(expenseId);
}
