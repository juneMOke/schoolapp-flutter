import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_header.dart';

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

  testWidgets('le mois du bandeau ouvre le sélecteur, qui ouvre un mois', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = await pumpPayrollScreen(tester, snapshot: snapshot());
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byTooltip('Choisir un mois')).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byTooltip('Choisir un mois'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('septembre 2026'));
    await tester.pumpAndSettle();

    expect(harness.cubit.state.month, '2026-09');
    expect(find.text('septembre 2026'), findsOneWidget);
  });

  group('PayrollLedgerHeader.firstPickable', () {
    PayrollState state(String month, PayrollSnapshot snapshot) => PayrollState(
      load: PayrollLoad.ready,
      snapshot: snapshot,
      today: '2026-10-15',
      month: month,
    );

    test('les douze mois qui finissent au mois en cours', () {
      expect(
        PayrollLedgerHeader.firstPickable(
          state('2026-08', PayrollSnapshot.empty),
        ),
        '2025-11',
      );
    });

    test('un mois plus ancien ouvre les douze mois qui partent de lui', () {
      expect(
        PayrollLedgerHeader.firstPickable(
          state('2024-03', PayrollSnapshot.empty),
        ),
        '2024-03',
      );
    });

    test('jamais avant le premier contrat', () {
      expect(
        PayrollLedgerHeader.firstPickable(state('2026-08', snapshot())),
        '2026-06',
      );
    });
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
