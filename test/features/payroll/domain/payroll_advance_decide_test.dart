import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/find_expense_use_case.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_advance_request_use_cases.dart';

class _MockExpenses extends Mock implements ExpenseRepository {}

/// Trancher une avance depuis la Paie : les gestes de la dépense, et ses
/// refus dits dans la langue de la Paie.
void main() {
  final expense = Expense(
    id: 'e-1',
    typeId: 't-adv',
    title: 'Avance',
    amountInCents: 30000,
    currency: 'USD',
    status: ExpenseStatus.pending,
    expenseDate: DateTime(2026, 10, 20),
    clientUpdatedAt: DateTime.utc(2026, 10, 20),
  );
  setUpAll(() {
    registerFallbackValue(ExpenseGesture.approve);
    registerFallbackValue(expense);
  });

  late _MockExpenses expenses;
  late DecideSalaryAdvanceUseCase decide;

  void answers(Either<Failure, Unit> result) => when(
    () => expenses.applyGesture(
      expense,
      any(),
      note: any(named: 'note'),
      actorName: any(named: 'actorName'),
      advancePayment: any(named: 'advancePayment'),
    ),
  ).thenAnswer((_) async => result);

  setUp(() {
    expenses = _MockExpenses();
    decide = DecideSalaryAdvanceUseCase(
      FindExpenseUseCase(expenses),
      ApplyExpenseGestureUseCase(expenses),
    );
  });

  PayrollRule? ruleOf(Either<Failure, Unit> result) => result.fold(
    (failure) => failure is PayrollRuleFailure ? failure.rule : null,
    (_) => null,
  );

  test('approuver passe le geste tel quel', () async {
    answers(const Right(unit));
    expect(await decide(expense, ExpenseGesture.approve), const Right(unit));
  });

  test('refuser sans motif ne part pas', () async {
    final result = await decide(expense, ExpenseGesture.refuse, note: '  ');
    expect(ruleOf(result), PayrollRule.reasonRequired);
    verifyNever(
      () => expenses.applyGesture(
        any(),
        any(),
        note: any(named: 'note'),
        actorName: any(named: 'actorName'),
        advancePayment: any(named: 'advancePayment'),
      ),
    );
  });

  test('un geste du demandeur n est pas offert par la Paie', () async {
    final result = await decide(expense, ExpenseGesture.retract);
    expect(ruleOf(result), PayrollRule.wrongPhase);
  });

  test(
    'un état qui a bougé, une preuve manquante : nommés pour la Paie',
    () async {
      answers(const Left(ConflictFailure('déjà tranchée')));
      expect(
        ruleOf(await decide(expense, ExpenseGesture.approve)),
        PayrollRule.wrongPhase,
      );
      answers(const Left(ValidationFailure('preuve requise')));
      expect(
        ruleOf(await decide(expense, ExpenseGesture.pay)),
        PayrollRule.signatureRequired,
      );
    },
  );

  test(
    'décaisser par mobile money sans référence : la référence est nommée',
    () async {
      final mobile = Expense(
        id: 'e-2',
        typeId: 't-adv',
        title: 'Avance',
        amountInCents: 30000,
        currency: 'USD',
        status: ExpenseStatus.approved,
        expenseDate: DateTime(2026, 10, 20),
        clientUpdatedAt: DateTime.utc(2026, 10, 20),
        fundingSource: ExpenseFundingSource.mobileMoney,
      );
      when(
        () => expenses.applyGesture(
          mobile,
          any(),
          note: any(named: 'note'),
          actorName: any(named: 'actorName'),
          advancePayment: any(named: 'advancePayment'),
        ),
      ).thenAnswer((_) async => const Left(ValidationFailure('preuve')));
      expect(
        ruleOf(await decide(mobile, ExpenseGesture.pay)),
        PayrollRule.invalidReference,
      );
    },
  );

  test(
    'décaisser refusé sur une demande encore accordée : le mois est fermé',
    () async {
      final approved = Expense(
        id: 'e-3',
        typeId: 't-adv',
        title: 'Avance',
        amountInCents: 30000,
        currency: 'USD',
        status: ExpenseStatus.approved,
        expenseDate: DateTime(2026, 10, 20),
        clientUpdatedAt: DateTime.utc(2026, 10, 20),
      );
      when(
        () => expenses.applyGesture(
          approved,
          any(),
          note: any(named: 'note'),
          actorName: any(named: 'actorName'),
          advancePayment: any(named: 'advancePayment'),
        ),
      ).thenAnswer((_) async => const Left(ConflictFailure('mois fermé')));
      when(() => expenses.find('e-3')).thenAnswer((_) async => Right(approved));
      expect(
        ruleOf(await decide(approved, ExpenseGesture.pay)),
        PayrollRule.monthLocked,
      );
    },
  );
}
