import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';

// Les gestes d'écriture du registre. Chacun réussit localement d'abord ; le
// serveur tranche plus tard, dans l'accusé (A4).

/// Créer, modifier ou dupliquer.
class SaveExpenseUseCase {
  final ExpenseRepository _repository;

  const SaveExpenseUseCase(this._repository);

  Future<Either<Failure, Expense>> call(ExpenseDraft draft) =>
      _repository.save(draft);
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

/// Poser un geste du circuit : approuver, refuser, payer, relancer, retirer,
/// renvoyer, annuler une décision, ou simplement commenter.
///
/// Un seul cas d'usage pour les huit : ce qui les distingue vit dans
/// `ExpenseGesture`, pas dans huit classes qui diraient la même phrase.
class ApplyExpenseGestureUseCase {
  final ExpenseRepository _repository;

  const ApplyExpenseGestureUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    Expense expense,
    ExpenseGesture gesture, {
    String note = '',
    String? actorName,
  }) => _repository.applyGesture(
    expense,
    gesture,
    note: note,
    actorName: actorName,
  );
}
