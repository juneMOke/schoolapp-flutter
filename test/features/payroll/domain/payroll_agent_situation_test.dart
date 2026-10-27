import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_request.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_agent_situations.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';

/// La fiche d'un agent : une vue sur les livres déjà calculés — ce que
/// l'école doit, l'année civile, les avances et l'ordre de parcours.
void main() {
  const current = '2026-10';

  PayrollLine line(
    String month, {
    String member = 'm-1',
    int gross = 35000,
    int net = 30000,
    String currency = 'USD',
    int formula = PayrollLine.currentFormula,
    PayrollLineDeductions deductions = const PayrollLineDeductions(
      iprInCents: 200,
      cnssInCents: 300,
      absenceInCents: 1500,
      childcareInCents: 1000,
    ),
    List<PayrollLineAdvance> advances = const [],
  }) => PayrollLine(
    month: month,
    staffMemberId: member,
    currency: currency,
    baseInCents: gross,
    grossInCents: gross,
    netInCents: net,
    formulaVersion: formula,
    deductions: deductions,
    advances: advances,
    frozen: true,
  );

  PayrollDisbursement paid(String month, int cents, {String member = 'm-1'}) =>
      PayrollDisbursement(
        id: 'd-$member-$month-$cents',
        month: month,
        staffMemberId: member,
        validationGestureId: 'g-$month',
        amount: Money(cents, 'USD'),
        mode: PayoutMode.cash,
        paidAt: '$month-28T09:00:00.000Z',
        signedRegister: true,
      );

  PayrollAdvanceRequest request(String id, ExpenseStatus status) =>
      PayrollAdvanceRequest(
        expenseId: id,
        block: const ExpenseStaffAdvance(
          staffMemberId: 'm-1',
          kind: ExpenseStaffAdvanceKind.loan,
          installments: 3,
          reason: 'MEDICAL',
        ),
        amount: const Money(30000, 'USD'),
        status: status,
        fundingSource: ExpenseFundingSource.cash,
      );

  PayrollSnapshot snapshotOf({
    required Map<String, List<PayrollLine>> frozen,
    List<PayrollDisbursement> disbursements = const [],
    List<SalaryAdvance> advances = const [],
    List<PayrollAdvanceRequest> requests = const [],
  }) => PayrollSnapshot(
    // L'état civil range m-2 avant m-1.
    members: [member('m-2'), member('m-1')],
    contractsByMember: {
      'm-1': [contract('m-1', from: '2025-01-01')],
      'm-2': [contract('m-2', from: '2025-01-01')],
    },
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {
      for (final month in frozen.keys)
        month: PayrollHeader(
          id: 'p-$month',
          month: month,
          status: PayrollStatus.validated,
          validationGestureId: 'g-$month',
        ),
    },
    variables: const {},
    frozenLines: frozen,
    summaries: const {},
    gestures: const [],
    advances: advances,
    advanceRequests: requests,
    disbursements: disbursements,
    schoolYears: const [],
    shareTraces: const {},
    hasEverSynced: true,
  );

  test('mois de l agent, du plus récent au plus ancien ; le mois en cours '
      'non validé est « prévu »', () {
    final snapshot = snapshotOf(
      frozen: {
        '2026-08': [line('2026-08')],
        '2026-09': [line('2026-09'), line('2026-09', member: 'm-2')],
      },
    );
    final situation = PayrollAgentSituations.of(
      snapshot,
      PayrollLedger.history(snapshot, current),
      staffMemberId: 'm-1',
      year: '2026',
      currentMonth: current,
    );

    expect(
      [for (final m in situation.months) m.month],
      ['2026-10', '2026-09', '2026-08'],
    );
    expect(situation.upcoming?.month, current);
    expect(situation.upcoming?.isLocked, isFalse);
  });

  test('reste dû : mois validés seulement ; une ligne v1 n est jamais une '
      'dette', () {
    final snapshot = snapshotOf(
      frozen: {
        '2026-07': [line('2026-07', formula: 1)],
        '2026-08': [line('2026-08')],
        '2026-09': [line('2026-09')],
      },
      disbursements: [paid('2026-08', 30000), paid('2026-09', 10000)],
    );
    final situation = PayrollAgentSituations.of(
      snapshot,
      PayrollLedger.history(snapshot, current),
      staffMemberId: 'm-1',
      year: '2026',
      currentMonth: current,
    );

    expect(situation.outstanding, {'USD': 20000});
    expect(situation.unsettledMonths, 1);
    expect(situation.arrears?.dueIn('USD'), 20000);
  });

  test('une ligne v1 est réputée versée : perçu = net, rien de dû', () {
    final snapshot = snapshotOf(
      frozen: {
        '2026-07': [line('2026-07', formula: 1)],
      },
    );
    final situation = PayrollAgentSituations.of(
      snapshot,
      PayrollLedger.history(snapshot, current),
      staffMemberId: 'm-1',
      year: '2026',
      currentMonth: current,
    );

    expect(situation.outstanding, isEmpty);
    expect(situation.totals.single.paidInCents, 30000);
    expect(situation.months.last.remainingInCents, 0);
  });

  test('validée sans ses lignes figées : ni reste ni cumul', () {
    final base = snapshotOf(
      frozen: {
        '2026-08': [line('2026-08')],
      },
    );
    // L'en-tête validé est là, ses lignes figées pas encore descendues.
    final snapshot = PayrollSnapshot(
      members: base.members,
      contractsByMember: base.contractsByMember,
      settings: base.settings,
      profiles: base.profiles,
      headers: base.headers,
      variables: base.variables,
      frozenLines: const {},
      summaries: base.summaries,
      gestures: base.gestures,
      advances: base.advances,
      disbursements: base.disbursements,
      schoolYears: base.schoolYears,
      shareTraces: base.shareTraces,
      hasEverSynced: true,
    );
    final situation = PayrollAgentSituations.of(
      snapshot,
      PayrollLedger.history(snapshot, current),
      staffMemberId: 'm-1',
      year: '2026',
      currentMonth: current,
    );

    expect(situation.outstanding, isEmpty);
    expect(situation.totals, isEmpty);
  });

  test('reste dû par devise', () {
    final snapshot = snapshotOf(
      frozen: {
        '2026-08': [line('2026-08', currency: 'CDF', net: 7000000)],
        '2026-09': [line('2026-09')],
      },
    );
    final situation = PayrollAgentSituations.of(
      snapshot,
      PayrollLedger.history(snapshot, current),
      staffMemberId: 'm-1',
      year: '2026',
      currentMonth: current,
    );

    expect(situation.outstanding, {'CDF': 7000000, 'USD': 30000});
  });

  test('cumuls : année civile, mois validés, une ligne par devise', () {
    final snapshot = snapshotOf(
      frozen: {
        '2025-12': [line('2025-12')],
        '2026-01': [
          line(
            '2026-01',
            advances: const [
              PayrollLineAdvance(
                advanceId: 'a-1',
                rank: 1,
                installments: 3,
                dueInCents: 10000,
                takenInCents: 10000,
                carriedInCents: 0,
              ),
            ],
          ),
        ],
        '2026-02': [line('2026-02')],
      },
      disbursements: [paid('2026-01', 30000), paid('2026-02', 12000)],
    );
    final situation = PayrollAgentSituations.of(
      snapshot,
      PayrollLedger.history(snapshot, current),
      staffMemberId: 'm-1',
      year: '2026',
      currentMonth: current,
    );

    final totals = situation.totals.single;
    expect(totals.currency, 'USD');
    expect(totals.months, 2);
    expect(totals.grossInCents, 70000);
    expect(totals.iprCnssInCents, 1000);
    expect(totals.absenceInCents, 3000);
    expect(totals.childcareInCents, 2000);
    expect(totals.advancesInCents, 10000);
    expect(totals.netInCents, 60000);
    expect(totals.paidInCents, 42000);
  });

  test('avances : la plus récente d abord, encours des seules vivantes', () {
    final snapshot = snapshotOf(
      frozen: const {},
      advances: [
        advance('m-1', id: 'a-1', amount: 30000, grantedOn: '2026-07-04'),
        advance('m-1', id: 'a-2', amount: 5000, grantedOn: '2026-09-10'),
        advance(
          'm-1',
          id: 'a-3',
          amount: 8000,
          grantedOn: '2026-09-12',
          syncState: RecordSyncState.failed,
        ),
        advance('m-2', id: 'a-4', amount: 9000),
      ],
    );
    final situation = PayrollAgentSituations.of(
      snapshot,
      PayrollLedger.history(snapshot, current),
      staffMemberId: 'm-1',
      year: '2026',
      currentMonth: current,
    );

    expect([for (final a in situation.advances) a.id], ['a-3', 'a-2', 'a-1']);
    expect(situation.loansOutstanding, {'USD': 35000});
  });

  test('demandes : dans le circuit ou refusées ; payées et reprises non', () {
    final snapshot = snapshotOf(
      frozen: const {},
      requests: [
        request('e-1', ExpenseStatus.pending),
        request('e-2', ExpenseStatus.approved),
        request('e-3', ExpenseStatus.refused),
        request('e-4', ExpenseStatus.paid),
        request('e-5', ExpenseStatus.retracted),
      ],
    );
    final situation = PayrollAgentSituations.of(
      snapshot,
      PayrollLedger.history(snapshot, current),
      staffMemberId: 'm-1',
      year: '2026',
      currentMonth: current,
    );

    expect(
      [for (final r in situation.requests) r.expenseId],
      ['e-1', 'e-2', 'e-3'],
    );
  });

  test('parcours : l ordre de l état civil, sans filtre', () {
    final snapshot = snapshotOf(
      frozen: {
        '2026-09': [line('2026-09'), line('2026-09', member: 'm-2')],
      },
    );
    final view = PayrollLedger.monthView(snapshot, '2026-09');

    expect(PayrollAgentSituations.roster(snapshot, view), ['m-2', 'm-1']);
  });
}
