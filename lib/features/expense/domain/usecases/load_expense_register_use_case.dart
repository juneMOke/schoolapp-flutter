import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';

/// Lit le registre local, ses types, le taux du jour et la rentrée.
class LoadExpenseRegisterUseCase {
  final ExpenseRepository _repository;

  const LoadExpenseRegisterUseCase(this._repository);

  Future<Either<Failure, ExpenseRegisterSnapshot>> call() =>
      _repository.loadRegister();
}
