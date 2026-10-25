import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_projection.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ids.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_advance_request_use_cases.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';

class _MockSave extends Mock implements SaveExpenseUseCase {}

/// Avance = demande de dépense (B5) : le dépôt, puis la projection au
/// paiement sous l'identifiant du serveur.
void main() {
  const expenseId = '7f3c2a10-1b2c-4d5e-8f90-a1b2c3d4e5f6';

  PayrollAdvanceRequest request({
    ExpenseStatus status = ExpenseStatus.paid,
    String? firstMonth = '2026-11',
  }) => PayrollAdvanceRequest(
    expenseId: expenseId,
    block: ExpenseStaffAdvance(
      staffMemberId: 'm-1',
      kind: ExpenseStaffAdvanceKind.loan,
      installments: 3,
      reason: 'MEDICAL',
      firstMonth: firstMonth,
    ),
    amount: const Money(30000, 'USD'),
    status: status,
    fundingSource: ExpenseFundingSource.mobileMoney,
    paidOn: '2026-10-20',
  );

  group('projection', () {
    test('payée : l avance attend sous l id du serveur (T10)', () {
      final projected = PayrollAdvanceProjection.of([request()], const []);

      final advance = projected.single;
      expect(advance.id, 'bd759072-c0ed-506c-a502-d263347edd73');
      expect(advance.firstMonth, '2026-11');
      expect(advance.installments, 3);
      expect(advance.reason, SalaryAdvanceReason.medical);
      expect(advance.mode, PayoutMode.mobileMoney);
      expect(advance.expenseId, expenseId);
    });

    test('accordée, sans mois, ou déjà descendue : rien de projeté', () {
      final served = advance(
        'm-1',
        id: PayrollIds.salaryAdvanceIdOf(expenseId),
      );

      expect(
        PayrollAdvanceProjection.of([
          request(status: ExpenseStatus.approved),
        ], const []),
        isEmpty,
      );
      expect(
        PayrollAdvanceProjection.of([request(firstMonth: null)], const []),
        isEmpty,
      );
      expect(PayrollAdvanceProjection.of([request()], [served]), isEmpty);
    });
  });

  group('dépôt', () {
    late _MockSave save;

    setUpAll(
      () => registerFallbackValue(
        ExpenseDraft(
          typeId: 't',
          title: 't',
          amountInCents: 0,
          currency: 'USD',
          expenseDate: DateTime(2026),
        ),
      ),
    );

    setUp(() {
      save = _MockSave();
      when(() => save(any())).thenAnswer(
        (invocation) async => Right(
          Expense(
            id: 'e-1',
            typeId: 't',
            title: 't',
            amountInCents: 0,
            currency: 'USD',
            status: ExpenseStatus.pending,
            expenseDate: DateTime(2026),
            clientUpdatedAt: DateTime(2026),
          ),
        ),
      );
    });

    PayrollSnapshot snapshot({String? typeId = 't-advance'}) => PayrollSnapshot(
      members: [member('m-1')],
      contractsByMember: {
        'm-1': [contract('m-1')],
      },
      settings: PayrollSettings.defaults,
      profiles: const {},
      headers: const {},
      variables: const {},
      frozenLines: const {},
      summaries: const {},
      gestures: const [],
      advances: const [],
      disbursements: const [],
      schoolYears: const [],
      shareTraces: const {},
      hasEverSynced: true,
      staffAdvanceTypeId: typeId,
    );

    SalaryAdvanceDraft draft({String currency = 'USD', int installments = 3}) =>
        SalaryAdvanceDraft(
          staffMemberId: 'm-1',
          amount: Money(30000, currency),
          installments: installments,
          firstMonth: '2026-10',
          reason: SalaryAdvanceReason.medical,
          mode: PayoutMode.cash,
          grantedOn: '2026-10-05',
        );

    test(
      'une demande STAFF_ADVANCE, intitulé sans nom, bloc R.H. complet',
      () async {
        final result = await RequestSalaryAdvanceUseCase(save)(
          snapshot(),
          draft(),
          title: 'Avance au personnel',
          today: DateTime(2026, 10, 5),
        );

        expect(result.isRight(), isTrue);
        final sent =
            verify(() => save(captureAny())).captured.single as ExpenseDraft;
        expect(sent.typeId, 't-advance');
        expect(sent.title, 'Avance au personnel');
        expect(sent.staffAdvance?.kind, ExpenseStaffAdvanceKind.loan);
        expect(sent.staffAdvance?.installments, 3);
        expect(sent.staffAdvance?.firstMonth, isNull);
        expect(sent.fundingSource, ExpenseFundingSource.cash);
      },
    );

    test(
      'sans type semé, hors devise du contrat, ou 5 échéances : refusé',
      () async {
        final useCase = RequestSalaryAdvanceUseCase(save);
        PayrollRule? rule(Either<dynamic, dynamic> r) =>
            r.fold((f) => (f as PayrollRuleFailure).rule, (_) => null);

        expect(
          rule(
            await useCase(
              snapshot(typeId: null),
              draft(),
              title: 'x',
              today: DateTime(2026, 10, 5),
            ),
          ),
          PayrollRule.advanceTypeMissing,
        );
        expect(
          rule(
            await useCase(
              snapshot(),
              draft(currency: 'CDF'),
              title: 'x',
              today: DateTime(2026, 10, 5),
            ),
          ),
          PayrollRule.invalidAmount,
        );
        expect(
          rule(
            await useCase(
              snapshot(),
              draft(installments: 5),
              title: 'x',
              today: DateTime(2026, 10, 5),
            ),
          ),
          PayrollRule.invalidInstallments,
        );
        verifyNever(() => save(any()));
      },
    );
  });
}
