import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_advance_request_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/salary_advance_dao.dart';
import 'package:school_app_flutter/features/payroll/data/repositories/payroll_expense_advance_guard.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/salary_advance_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ids.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

/// La Paie lit les demandes d'avance du registre des dépenses, et tient le
/// port de garde des Dépenses (B6).
void main() {
  const school = 's-1';
  const expenseId = '7f3c2a10-1b2c-4d5e-8f90-a1b2c3d4e5f6';
  late Database db;

  setUp(() async {
    db = await openFullOfflineDb();
    await db.insert('ref_expense_types', {
      'id': 't-advance',
      'school_id': school,
      'code': ExpenseStaffAdvance.typeCode,
      'label': 'Avance au personnel',
      'short_label': 'Avance',
      'icon': 'hand-coins',
      'color': '#8A5A12',
      'soft_color': '#FAF2E2',
      'default_currency': 'USD',
    });
    await db.insert('expenses', {
      'id': expenseId,
      'school_id': school,
      'type_id': 't-advance',
      'title': 'Avance au personnel',
      'amount_in_cents': 30000,
      'currency': 'USD',
      'status': ExpenseStatus.paid.wireValue,
      'paid_on': '2026-10-20',
      'expense_date': '2026-10-05',
      'staff_advance': const ExpenseStaffAdvance(
        staffMemberId: 'm-1',
        kind: ExpenseStaffAdvanceKind.advance,
        installments: 1,
        reason: 'RENT',
        firstMonth: '2026-11',
      ).encode(),
      'funding_source': 'CASH',
      'client_updated_at': '2026-10-05T09:00:00Z',
    });
  });
  tearDown(() => db.close());

  test('les demandes et le type semé se lisent dans le registre', () async {
    final dao = PayrollAdvanceRequestDao(db);

    final request = (await dao.forSchool(school)).single;
    expect(request.status, ExpenseStatus.paid);
    expect(request.block.firstMonth, '2026-11');
    expect(await dao.staffAdvanceTypeId(school), 't-advance');
  });

  group('garde', () {
    late PayrollExpenseAdvanceGuard guard;

    setUp(
      () => guard = PayrollExpenseAdvanceGuard(
        payrolls: PayrollDao(db),
        advances: SalaryAdvanceDao(db),
        currentUser: CurrentUserContext()..set('u-1', schoolId: school),
      ),
    );

    Future<void> served(String id, {String? cancelledAt}) =>
        SalaryAdvanceDao(db).applyPulled(
          [
            SalaryAdvanceDto.tryParse({
              'id': id,
              'staffMemberId': 'm-1',
              'amountInCents': 30000,
              'currency': 'USD',
              'installments': 1,
              'firstMonth': '2026-11',
              'reason': 'RENT',
              'mode': 'CASH',
              'grantedOn': '2026-10-20',
              'expenseId': expenseId,
              'cancelledAt': cancelledAt,
              'cancellationReason': cancelledAt == null ? null : 'Rouverte',
            })!,
          ],
          schoolId: school,
          nowMs: 1,
        );

    Future<void> validated(
      String month, {
      bool deducting = false,
      String status = 'VALIDATED',
      String? advanceId,
    }) => PayrollDao(db).apply(
      [
        PayrollDto.tryParse({
          'id': 'p-$month',
          'month': month,
          'status': status,
          'validationGestureId': 'g-$month',
          'lines': [
            {
              'staffMemberId': 'm-1',
              'currency': 'USD',
              'grossInCents': 30000,
              'netInCents': 0,
              'advances': [
                if (deducting)
                  {
                    'advanceId':
                        advanceId ?? PayrollIds.salaryAdvanceIdOf(expenseId),
                    'rank': 1,
                    'dueInCents': 30000,
                    'takenInCents': 30000,
                    'carriedInCents': 0,
                  },
              ],
            },
          ],
        })!,
      ],
      schoolId: school,
      nowMs: 1,
    );

    test('une paie absente reçoit la retenue, une paie validée non', () async {
      await validated('2026-10');

      expect(await guard.acceptsFirstMonth('2026-11'), isTrue);
      expect(await guard.acceptsFirstMonth('2026-10'), isFalse);
    });

    test('une retenue figée interdit la réouverture', () async {
      expect(await guard.isDeducted(expenseId), isFalse);

      await validated('2026-11', deducting: true);

      expect(await guard.isDeducted(expenseId), isTrue);
    });

    test('repayée : la retenue de l avance de rang 2 compte aussi', () async {
      final second = PayrollIds.salaryAdvanceIdOf(expenseId, payment: 2);
      await served(
        PayrollIds.salaryAdvanceIdOf(expenseId),
        cancelledAt: '2026-10-21T09:00:00Z',
      );
      await served(second);

      await validated('2026-11', deducting: true, advanceId: second);

      expect(await guard.isDeducted(expenseId), isTrue);
    });

    test('une paie soumise au mois de la retenue, ou après, bloque', () async {
      expect(
        await guard.isMonthLocked(expenseId, firstMonth: '2026-11'),
        isFalse,
      );

      await validated('2026-12', status: 'SUBMITTED');

      expect(
        await guard.isMonthLocked(expenseId, firstMonth: '2026-11'),
        isTrue,
      );
      expect(await guard.isMonthLocked(expenseId), isFalse);
    });

    test('l avance descendue fixe le mois, pas la saisie du poste', () async {
      await served(PayrollIds.salaryAdvanceIdOf(expenseId));
      await validated('2026-11', status: 'SUBMITTED');

      expect(await guard.isMonthLocked(expenseId), isTrue);
    });
  });
}
