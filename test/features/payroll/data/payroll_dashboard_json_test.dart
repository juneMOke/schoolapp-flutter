import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/data/dashboard/payroll_dashboard_json.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';

Map<String, dynamic> payrollDashboardFixture() =>
    jsonDecode(
          File(
            'test/fixtures/payroll/payroll_dashboard_response.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  test('lit la réponse du serveur, devise par devise', () {
    final dashboard = PayrollDashboardJson.fromJson(payrollDashboardFixture());

    expect(dashboard.month, '2026-09');
    expect(dashboard.status, PayrollMonthStatus.validated);
    expect(dashboard.provisional, isFalse);
    final usd = dashboard.section('USD')!;
    final forecast = usd.forecast;
    // L'invariant du serveur : les retenues prises séparent le brut du net.
    expect(
      forecast.netInCents +
          forecast.absenceInCents +
          forecast.legalInCents +
          forecast.childcareInCents +
          forecast.advancesInCents,
      forecast.grossInCents,
    );
    expect(forecast.employerChargesInCents, 6080);
    expect(usd.progress!.totalInCents, forecast.netInCents);
    expect(usd.progress!.outstandingInCents, 15000);
    expect(usd.rows.map((r) => r.status), [
      PayrollDashboardStatus.settled,
      PayrollDashboardStatus.due,
    ]);
    expect(usd.rows.last.jobTitle, isNull);
    expect(usd.totals!.remainingInCents, 18000);
  });

  test('les mois, les avances et les arriérés', () {
    final dashboard = PayrollDashboardJson.fromJson(payrollDashboardFixture());

    expect(dashboard.months.first.isFullyPaid, isTrue);
    expect(dashboard.months.last.isFullyPaid, isFalse);
    expect(dashboard.months.last.byCurrency['USD']!.unpaidInCents, 10000);
    final advance = dashboard.advances.single;
    expect(advance.isLoan, isTrue);
    expect(advance.reason, SalaryAdvanceReason.medical);
    expect(advance.phase, PayrollAdvancePhase.inProgress);
    expect(advance.repaidShare, 0.5);
    expect(dashboard.arrears.single.dueIn('USD'), 3000);
    expect(dashboard.arrears.single.dues.single.prioritized, isTrue);
  });

  test('un mois d avant la v2 : ni répartition, ni lignes, ni total', () {
    final json = payrollDashboardFixture()..['tracked'] = false;
    final section = (json['currencies'] as List).first as Map<String, dynamic>
      ..remove('progress')
      ..remove('rows')
      ..remove('totals');
    expect(section.containsKey('rows'), isFalse);

    final dashboard = PayrollDashboardJson.fromJson(json);

    expect(dashboard.tracked, isFalse);
    expect(dashboard.section('USD')!.progress, isNull);
    expect(dashboard.section('USD')!.rows, isEmpty);
    expect(dashboard.section('USD')!.totals, isNull);
  });

  test('un montant manquant fait échouer la lecture', () {
    final json = payrollDashboardFixture();
    (((json['currencies'] as List).first as Map)['forecast'] as Map).remove(
      'netInCents',
    );

    expect(() => PayrollDashboardJson.fromJson(json), throwsA(anything));
  });

  test('des lignes filtrées à zéro ne vident pas le mois', () {
    final json = payrollDashboardFixture()..['status'] = 'NONE';
    ((json['currencies'] as List).first as Map)['rows'] = <Object>[];

    expect(PayrollDashboardJson.fromJson(json).isEmpty, isFalse);
  });
}
