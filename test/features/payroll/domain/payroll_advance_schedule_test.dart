import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_schedule.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../payroll_builders.dart';

List<PayrollLineAdvance> deduct({
  required String month,
  required String currency,
  required int grossInCents,
  required List<SalaryAdvance> advances,
  required List<PayrollLine> priorLines,
}) => PayrollAdvanceSchedule.deduct(
  month: month,
  currency: currency,
  grossInCents: grossInCents,
  states: [
    for (final states in PayrollAdvanceSchedule.statesOf(
      advances,
      month,
      priorLines,
    ).values)
      ...states,
  ],
);

void main() {
  test('100 USD sur 3 mois : 33,33 · 33,33 · 33,34', () {
    final plan = advance(
      'm-1',
      amount: 10000,
      installments: 3,
      firstMonth: '2026-10',
    );
    final first = deduct(
      month: '2026-10',
      currency: 'USD',
      grossInCents: 50000,
      advances: [plan],
      priorLines: const [],
    ).single;
    final second = deduct(
      month: '2026-11',
      currency: 'USD',
      grossInCents: 50000,
      advances: [plan],
      priorLines: [frozenLine('m-1', '2026-10', advanceId: 'a-1', taken: 3333)],
    ).single;
    final third = deduct(
      month: '2026-12',
      currency: 'USD',
      grossInCents: 50000,
      advances: [plan],
      priorLines: [
        frozenLine('m-1', '2026-10', advanceId: 'a-1', taken: 3333),
        frozenLine('m-1', '2026-11', advanceId: 'a-1', taken: 3333),
      ],
    ).single;

    expect(
      [first.takenInCents, second.takenInCents, third.takenInCents],
      [3333, 3333, 3334],
    );
    expect(third.rank, 3);
  });

  test('un brut nul reporte l échéance, le mois suivant rattrape', () {
    final plan = advance('m-1', amount: 6000, installments: 3);
    final empty = deduct(
      month: '2026-10',
      currency: 'USD',
      grossInCents: 0,
      advances: [plan],
      priorLines: const [],
    ).single;
    final next = deduct(
      month: '2026-11',
      currency: 'USD',
      grossInCents: 22800,
      advances: [plan],
      priorLines: [frozenLine('m-1', '2026-10', gross: 0)],
    ).single;

    expect(empty.dueInCents, 2000);
    expect(empty.takenInCents, 0);
    expect(empty.carriedInCents, 2000);
    expect(next.rank, 2);
    expect(next.takenInCents, 4000);
  });

  test('un été sans paie ne fait pas mûrir d échéance (Q4)', () {
    final plan = advance(
      'm-1',
      amount: 6000,
      installments: 3,
      firstMonth: '2026-06',
    );
    final september = deduct(
      month: '2026-09',
      currency: 'USD',
      grossInCents: 35000,
      advances: [plan],
      priorLines: [frozenLine('m-1', '2026-06', advanceId: 'a-1', taken: 2000)],
    ).single;

    expect(september.rank, 2);
    expect(september.takenInCents, 2000);
  });

  test('plusieurs avances se partagent le brut dans l ordre de départ', () {
    final older = advance(
      'm-1',
      id: 'a-old',
      amount: 3000,
      firstMonth: '2026-09',
    );
    final newer = advance('m-1', id: 'a-new', amount: 3000);
    final result = deduct(
      month: '2026-10',
      currency: 'USD',
      grossInCents: 4000,
      advances: [newer, older],
      priorLines: const [],
    );

    expect(result.map((a) => a.advanceId), ['a-old', 'a-new']);
    expect(result.map((a) => a.takenInCents), [3000, 1000]);
    expect(result.last.carriedInCents, 2000);
  });

  test('ni autre devise, ni refusée, ni soldée, ni pas encore commencée', () {
    final result = deduct(
      month: '2026-10',
      currency: 'USD',
      grossInCents: 35000,
      advances: [
        advance('m-1', id: 'cdf', currency: 'CDF'),
        advance('m-1', id: 'refused', syncState: StaffSyncState.failed),
        advance('m-1', id: 'later', firstMonth: '2026-11'),
        advance('m-1', id: 'settled', amount: 1000, firstMonth: '2026-09'),
      ],
      priorLines: [
        frozenLine('m-1', '2026-09', advanceId: 'settled', taken: 1000),
      ],
    );

    expect(result, isEmpty);
  });
}
