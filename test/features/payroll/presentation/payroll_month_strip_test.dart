import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_month_pill.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

void main() {
  PayrollSnapshot snapshot() => PayrollSnapshot(
    members: [member('m-1', lastName: 'Mayala', firstName: 'Ruth')],
    contractsByMember: {
      'm-1': [contract('m-1', from: '2026-06-01')],
    },
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {
      '2026-09': const PayrollHeader(
        id: 'p-09',
        month: '2026-09',
        status: PayrollStatus.validated,
        validationGestureId: 'g-v',
      ),
    },
    variables: const {},
    frozenLines: {
      '2026-09': [frozenLine('m-1', '2026-09')],
    },
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: const [],
    schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );

  group('PayrollMonth', () {
    test('compte les mois et lit un mois bien formé', () {
      expect(PayrollMonth.between('2025-11', '2026-02'), 3);
      expect(PayrollMonth.between('2026-02', '2025-11'), -3);
      expect(PayrollMonth.parse('2026-09'), '2026-09');
      expect(PayrollMonth.parse('2026-13'), isNull);
      expect(PayrollMonth.parse('sept'), isNull);
      expect(PayrollMonth.parse(null), isNull);
    });
  });

  testWidgets('une pastille par mois, du premier contrat au mois en cours', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpPayrollScreen(tester, snapshot: snapshot());
    await tester.pumpAndSettle();

    final pills = tester
        .widgetList<PayrollMonthPill>(find.byType(PayrollMonthPill))
        .toList();
    expect(pills.map((p) => p.month), [
      '2026-10',
      '2026-09',
      '2026-08',
      '2026-07',
      '2026-06',
    ]);
    expect(pills.firstWhere((p) => p.month == '2026-09').phase, isNotNull);
    expect(pills.firstWhere((p) => p.month == '2026-07').phase, isNull);
    expect(pills.firstWhere((p) => p.month == '2026-10').selected, isTrue);
  });

  testWidgets('toucher une pastille ouvre son mois', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = await pumpPayrollScreen(tester, snapshot: snapshot());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is PayrollMonthPill && w.month == '2026-09',
      ),
    );
    await tester.pumpAndSettle();

    expect(harness.cubit.state.month, '2026-09');
    expect(find.text('septembre 2026'), findsOneWidget);
  });

  testWidgets(
    'un mois d adresse est ramené entre le premier contrat et ce mois',
    (tester) async {
      final harness = await pumpPayrollScreen(tester, snapshot: snapshot());
      await tester.pumpAndSettle();
      final cubit = harness.cubit;

      cubit.showMonth('2027-03');
      expect(cubit.state.month, '2026-10');
      cubit.showMonth('2025-01');
      expect(cubit.state.month, '2026-06');
      cubit.showMonth('n importe quoi');
      expect(cubit.state.month, '2026-10');
      cubit.showMonth('2026-08');
      expect(cubit.state.month, '2026-08');
    },
  );

  testWidgets('un mois d adresse lu avant la tablette est borné à sa lecture', (
    tester,
  ) async {
    final harness = await pumpPayrollScreen(
      tester,
      snapshot: snapshot(),
      // Avant la lecture, le premier contrat est inconnu : rien ne borne.
      beforeLoad: (cubit) => cubit.showMonth('2019-01'),
    );
    await tester.pumpAndSettle();

    expect(harness.cubit.state.month, '2026-06');
  });
}
