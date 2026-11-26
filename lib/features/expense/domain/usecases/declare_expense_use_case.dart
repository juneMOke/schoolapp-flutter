import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_declaration_repository.dart';

class DeclareExpenseUseCase {
  final ExpenseDeclarationRepository _repository;

  const DeclareExpenseUseCase(this._repository);

  Future<Either<Failure, Expense>> call(ExpenseDeclarationDraft draft) =>
      _repository.declare(draft);
}
