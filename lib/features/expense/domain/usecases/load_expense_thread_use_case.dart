import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';

/// Lit le fil d'une demande — 100 % local, comme tout ce que le module
/// affiche : la fiche s'ouvre sans réseau, même au fond d'une cour d'école.
class LoadExpenseThreadUseCase {
  final ExpenseRepository _repository;

  const LoadExpenseThreadUseCase(this._repository);

  Future<Either<Failure, List<ExpenseMessage>>> call(String expenseId) =>
      _repository.thread(expenseId);
}
