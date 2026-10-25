import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_advances_page.dart';

import '../../staff/staff_builders.dart';
import 'payroll_screen_harness.dart';

class _MockExpenses extends Mock implements ExpenseRepository {}

/// RH · Paie ▸ Avances & prêts : la direction approuve ou refuse, la caisse
/// décaisse, sans passer par les Dépenses (spec §10) — avec les gestes de la
/// dépense elle-même.
void main() {
  setUpAll(() {
    registerFallbackValue(ExpenseGesture.approve);
    registerFallbackValue(
      Expense(
        id: 'fallback',
        typeId: 't',
        title: '',
        amountInCents: 1,
        currency: 'USD',
        status: ExpenseStatus.pending,
        expenseDate: DateTime(2026),
        clientUpdatedAt: DateTime.utc(2026),
      ),
    );
  });

  const block = ExpenseStaffAdvance(
    staffMemberId: 'm-1',
    kind: ExpenseStaffAdvanceKind.loan,
    installments: 3,
    reason: 'MEDICAL',
  );

  Expense expenseOf(ExpenseStatus status) => Expense(
    id: 'e-1',
    typeId: 't-adv',
    title: 'Avance sur salaire',
    amountInCents: 30000,
    currency: 'USD',
    status: status,
    expenseDate: DateTime(2026, 10, 20),
    clientUpdatedAt: DateTime.utc(2026, 10, 20),
    staffAdvance: block,
  );

  PayrollSnapshot snapshotWith(ExpenseStatus status) => PayrollSnapshot(
    members: [member('m-1', lastName: 'Mayala', firstName: 'Ruth')],
    contractsByMember: const {},
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: const {},
    variables: const {},
    frozenLines: const {},
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: const [],
    schoolYears: const [(start: '2025-09-01', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
    staffAdvanceTypeId: 't-adv',
    advanceRequests: [
      PayrollAdvanceRequest(
        expenseId: 'e-1',
        block: block,
        amount: const Money(30000, 'USD'),
        status: status,
        fundingSource: ExpenseFundingSource.cash,
        decidedAt: status == ExpenseStatus.approved
            ? '2026-10-21T09:00:00.000Z'
            : null,
        decidedByName: status == ExpenseStatus.approved ? 'Kalala' : null,
      ),
    ],
  );

  late _MockExpenses expenses;

  Future<void> pump(
    WidgetTester tester,
    ExpenseStatus status,
    List<Perm> permissions,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    expenses = _MockExpenses();
    when(
      () => expenses.find('e-1'),
    ).thenAnswer((_) async => Right(expenseOf(status)));
    when(
      () => expenses.applyGesture(
        any(),
        any(),
        note: any(named: 'note'),
        actorName: any(named: 'actorName'),
        advancePayment: any(named: 'advancePayment'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    await pumpPayrollScreen(
      tester,
      snapshot: snapshotWith(status),
      permissions: permissions,
      expenses: expenses,
      child: const PayrollAdvancesScreen(),
    );
  }

  testWidgets('la direction approuve depuis la Paie', (tester) async {
    await pump(tester, ExpenseStatus.pending, const [
      Perm.hrPayRead,
      Perm.expenseDecide,
    ]);

    await tester.tap(find.text('Approuver'));
    await tester.pumpAndSettle();

    verify(
      () => expenses.applyGesture(
        any(that: isA<Expense>().having((e) => e.id, 'id', 'e-1')),
        ExpenseGesture.approve,
        note: '',
        actorName: any(named: 'actorName'),
        advancePayment: null,
      ),
    ).called(1);
    expect(find.textContaining('approuvée ·'), findsOneWidget);
  });

  testWidgets('refuser exige un motif, transmis avec le geste', (tester) async {
    await pump(tester, ExpenseStatus.pending, const [
      Perm.hrPayRead,
      Perm.expenseDecide,
    ]);

    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();
    expect(find.text("Refuser la demande d'avance"), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Budget épuisé');
    await tester.tap(find.text('Refuser la demande'));
    await tester.pumpAndSettle();

    verify(
      () => expenses.applyGesture(
        any(),
        ExpenseGesture.refuse,
        note: 'Budget épuisé',
        actorName: any(named: 'actorName'),
        advancePayment: null,
      ),
    ).called(1);
  });

  testWidgets('l économe lit qui est attendu, sans bouton', (tester) async {
    await pump(tester, ExpenseStatus.pending, const [
      Perm.hrPayRead,
      Perm.hrPayWrite,
    ]);

    expect(find.text('Attend la direction'), findsOneWidget);
    expect(find.text('Approuver'), findsNothing);
  });

  testWidgets(
    'accordée : la caisse décaisse ; les autres attendent la caisse',
    (tester) async {
      await pump(tester, ExpenseStatus.approved, const [
        Perm.hrPayRead,
        Perm.expensePay,
      ]);
      expect(find.text('Décaisser'), findsOneWidget);
      expect(find.textContaining('approuvée le'), findsOneWidget);

      await pump(tester, ExpenseStatus.approved, const [
        Perm.hrPayRead,
        Perm.expenseDecide,
      ]);
      expect(find.text('Décaisser'), findsNothing);
      expect(find.text('Attend la caisse'), findsOneWidget);
    },
  );
}
