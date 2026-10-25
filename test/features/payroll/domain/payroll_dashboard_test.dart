import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_dashboard_figures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';

/// Le tableau de bord applique, sur les lignes du livre, les définitions
/// figées avec le back pour le PDF (Q7) : prévu = brut, retenues = absence +
/// IPR + CNSS + PC/E + avances, arriérés = dû antérieur, perçu = versé sur la
/// ligne, reste = net + arriérés − perçu.
void main() {
  PayrollLine line(
    String id,
    String month, {
    int gross = 40000,
    int net = 30000,
    int absence = 2000,
    int ipr = 200,
    int cnss = 1000,
    int childcare = 800,
    int? toPay,
  }) => PayrollLine(
    month: month,
    staffMemberId: id,
    currency: 'USD',
    baseInCents: gross,
    grossInCents: gross,
    netInCents: net,
    formulaVersion: 2,
    deductions: PayrollLineDeductions(
      absenceInCents: absence,
      iprInCents: ipr,
      cnssInCents: cnss,
      childcareInCents: childcare,
    ),
    payout: toPay == null
        ? null
        : PayrollLinePayout(
            toPayInCents: toPay,
            deferredInCents: net - toPay,
            ratePercent: 50,
          ),
    frozen: true,
  );

  PayrollHeader validated(String month) => PayrollHeader(
    id: 'p-$month',
    month: month,
    status: PayrollStatus.validated,
    validationGestureId: 'g-$month',
  );

  PayrollDisbursement paid(String id, String member, String month, int cents) =>
      PayrollDisbursement(
        id: id,
        month: month,
        staffMemberId: member,
        validationGestureId: 'g-$month',
        amount: Money(cents, 'USD'),
        mode: PayoutMode.cash,
        paidAt: '$month-28T09:00:00.000Z',
        signedRegister: true,
      );

  final snapshot = PayrollSnapshot(
    members: const [],
    contractsByMember: const {},
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {'2026-08': validated('2026-08'), '2026-09': validated('2026-09')},
    variables: const {},
    frozenLines: {
      '2026-08': [line('m-1', '2026-08')],
      '2026-09': [
        line('m-1', '2026-09'),
        line('m-2', '2026-09', toPay: 15000),
        line('m-3', '2026-09'),
      ],
    },
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: [
      // Août : 10 000 versés sur 30 000 → 20 000 d'arriérés pour m-1.
      paid('d-1', 'm-1', '2026-08', 10000),
      // Septembre : m-1 soldé, m-2 a reçu la part prévue, m-3 rien.
      paid('d-2', 'm-1', '2026-09', 30000),
      paid('d-3', 'm-2', '2026-09', 15000),
    ],
    schoolYears: const [(start: '2025-09-01', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );
  final september = PayrollLedger.monthView(snapshot, '2026-09');
  final arrears = PayrollArrears.of(snapshot, currentMonth: '2026-10');

  test('prévu, retenues par nature et réel du mois', () {
    final forecast = PayrollDashboard.forecastOf(september, 'USD');
    expect(forecast.grossInCents, 120000);
    expect(forecast.absenceInCents, 6000);
    expect(forecast.legalInCents, 3600);
    expect(forecast.childcareInCents, 2400);
    expect(forecast.netInCents, 90000);
    expect(forecast.savedInCents, 30000);
    // 30 000 − 6 000 − 3 600 − 2 400 : l'écart que nos lignes ne nomment pas.
    expect(forecast.otherInCents, 18000);
  });

  test('payé, reporté par décision, non payé', () {
    final progress = PayrollDashboard.progressOf(september, 'USD');
    expect(progress.paidInCents, 45000);
    expect(progress.deferredInCents, 15000);
    expect(progress.unpaidInCents, 30000);
    expect(progress.settledCount, 1);
    expect(progress.partialCount, 1);
    expect(progress.unpaidCount, 1);
  });

  test('les lignes : arriérés antérieurs, perçu, reste et statut', () {
    final rows = {
      for (final row in PayrollDashboard.rowsOf(september, arrears))
        row.staffMemberId: row,
    };
    final m1 = rows['m-1']!;
    expect(m1.plannedInCents, 40000);
    expect(m1.deductionsInCents, 4000);
    expect(m1.arrearsInCents, 20000);
    expect(m1.receivedInCents, 30000);
    expect(m1.remainingInCents, 20000);
    expect(m1.status, PayrollDashboardStatus.partial);
    expect(rows['m-2']!.status, PayrollDashboardStatus.partial);
    expect(rows['m-3']!.status, PayrollDashboardStatus.due);
    expect(rows['m-3']!.remainingInCents, 30000);
  });

  test('un mois en brouillon : tout « à verser », rien de perçu', () {
    final draft = PayrollLedger.monthView(
      const PayrollSnapshot(
        members: [],
        contractsByMember: {},
        settings: PayrollSettings.defaults,
        profiles: {},
        headers: {},
        variables: {},
        frozenLines: {},
        summaries: {},
        gestures: [],
        advances: [],
        disbursements: [],
        schoolYears: [(start: '2025-09-01', end: '2027-07-02')],
        shareTraces: {},
        hasEverSynced: true,
      ),
      '2026-10',
    );
    final progress = PayrollDashboard.progressOf(draft, 'USD');
    expect(progress.paidInCents, 0);
    expect(PayrollDashboard.rowsOf(draft, const []), isEmpty);
  });

  test('les filtres du PDF : « reste à payer » garde partiels et dus', () {
    expect(
      PayrollDashboardFilter.outstanding.keeps(PayrollDashboardStatus.partial),
      isTrue,
    );
    expect(
      PayrollDashboardFilter.outstanding.keeps(PayrollDashboardStatus.settled),
      isFalse,
    );
    expect(
      PayrollDashboardFilter.outstanding.keeps(
        PayrollDashboardStatus.toDisburse,
      ),
      isTrue,
    );
    expect(
      PayrollDashboardFilter.settled.keeps(PayrollDashboardStatus.toDisburse),
      isFalse,
    );
    expect(PayrollDashboardFilter.outstanding.wire, 'OUTSTANDING');
  });
}
