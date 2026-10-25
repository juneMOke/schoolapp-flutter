import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_arrears_use_cases.dart';

import '../../staff/staff_builders.dart';

/// Le registre des arriérés (B4) : dérivé des paies validées, imputé au mois
/// d'origine, réparti du plus ancien au plus récent.
void main() {
  PayrollLine line(
    String month, {
    int net = 20000,
    int? toPay,
    int formula = PayrollLine.currentFormula,
  }) => PayrollLine(
    month: month,
    formulaVersion: formula,
    staffMemberId: 'm-1',
    currency: 'USD',
    baseInCents: net,
    grossInCents: net,
    netInCents: net,
    frozen: true,
    payout: toPay == null
        ? null
        : PayrollLinePayout(toPayInCents: toPay, deferredInCents: net - toPay),
  );

  PayrollDisbursement paid(String month, int cents) => PayrollDisbursement(
    id: 'd-$month-$cents',
    month: month,
    staffMemberId: 'm-1',
    validationGestureId: 'g-$month',
    amount: Money(cents, 'USD'),
    mode: PayoutMode.cash,
    paidAt: '$month-28T09:00:00.000Z',
    signedRegister: true,
  );

  PayrollSnapshot snapshotOf({
    required Map<String, PayrollLine> lines,
    List<PayrollDisbursement> disbursements = const [],
    Set<String> priorities = const {},
  }) => PayrollSnapshot(
    members: [member('m-1')],
    contractsByMember: const {},
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {
      for (final month in lines.keys)
        month: PayrollHeader(
          id: 'p-$month',
          month: month,
          status: PayrollStatus.validated,
          validationGestureId: 'g-$month',
        ),
    },
    variables: const {},
    frozenLines: {
      for (final entry in lines.entries) entry.key: [entry.value],
    },
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: disbursements,
    schoolYears: const [],
    shareTraces: const {},
    hasEverSynced: true,
    arrearsPriorities: priorities,
  );

  test('acompte, impayé, différé : origine et dû par mois d origine', () {
    final agents = PayrollArrears.of(
      snapshotOf(
        lines: {
          '2026-08': line('2026-08'),
          '2026-09': line('2026-09'),
          '2026-10': line('2026-10', toPay: 12000),
        },
        disbursements: [paid('2026-09', 5000), paid('2026-10', 12000)],
      ),
      currentMonth: '2026-10',
    );

    final months = agents.single.months;
    expect(
      [for (final a in months) a.month],
      ['2026-08', '2026-09', '2026-10'],
    );
    expect(
      [for (final a in months) a.origin],
      [
        PayrollArrearOrigin.unpaid,
        PayrollArrearOrigin.partial,
        PayrollArrearOrigin.deferred,
      ],
    );
    expect([for (final a in months) a.dueInCents], [20000, 15000, 8000]);
    expect(agents.single.dueIn('USD'), 43000);
  });

  test('mois en cours : la part différée compte, même rien versé', () {
    final agents = PayrollArrears.of(
      snapshotOf(lines: {'2026-10': line('2026-10', toPay: 12000)}),
      currentMonth: '2026-10',
    );

    final arrear = agents.single.months.single;
    expect(arrear.origin, PayrollArrearOrigin.deferred);
    expect(arrear.dueInCents, 8000);
  });

  test('le mois en cours non versé n est pas un arriéré', () {
    final agents = PayrollArrears.of(
      snapshotOf(lines: {'2026-10': line('2026-10')}),
      currentMonth: '2026-10',
    );

    expect(agents, isEmpty);
  });

  test('une paie validée avant la v2 ne compte jamais comme arriéré', () {
    final agents = PayrollArrears.of(
      snapshotOf(
        lines: {
          '2026-08': line('2026-08', formula: 1),
          '2026-09': line('2026-09'),
        },
      ),
      currentMonth: '2026-10',
    );

    expect([for (final a in agents.single.months) a.month], ['2026-09']);
  });

  test('le drapeau priorité suit le mois d origine', () {
    final agent = PayrollArrears.of(
      snapshotOf(
        lines: {'2026-08': line('2026-08')},
        priorities: {PayrollArrears.priorityKey('2026-08', 'm-1')},
      ),
      currentMonth: '2026-10',
    ).single;

    expect(agent.prioritized, isTrue);
  });

  group('versement réparti', () {
    final snapshot = snapshotOf(
      lines: {'2026-08': line('2026-08'), '2026-09': line('2026-09')},
      disbursements: [paid('2026-09', 5000)],
    );
    final agent = PayrollArrears.of(snapshot, currentMonth: '2026-10').single;
    const proof = PayrollDisbursementDraft(
      month: '',
      staffMemberId: 'm-1',
      validationGestureId: '',
      amount: Money(0, 'USD'),
      mode: PayoutMode.cash,
      signedRegister: true,
    );

    test('du plus ancien au plus récent, un versement par mois', () {
      final drafts = PayPayrollArrearsUseCase.draftsOf(
        snapshot,
        agent,
        currency: 'USD',
        amountInCents: 25000,
        proof: proof,
      ).getOrElse(() => throw StateError('refusé'));

      expect([for (final d in drafts) d.month], ['2026-08', '2026-09']);
      expect([for (final d in drafts) d.amount.amountInCents], [20000, 5000]);
      expect(
        [for (final d in drafts) d.validationGestureId],
        ['g-2026-08', 'g-2026-09'],
      );
    });

    test('au-delà du dû : refusé avant la file', () {
      final refused = PayPayrollArrearsUseCase.draftsOf(
        snapshot,
        agent,
        currency: 'USD',
        amountInCents: 35001,
        proof: proof,
      );

      expect(
        refused.fold((rule) => rule, (_) => null),
        PayrollRule.exceedsBalance,
      );
    });
  });
}
