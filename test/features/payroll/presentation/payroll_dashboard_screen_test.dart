import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_dashboard_page.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import 'payroll_screen_harness.dart';

class _MockPayslips extends Mock implements PayslipRepository {}

/// RH · Paie ▸ Tableau de bord : prévu et réel, payé et non payé, prêts,
/// arriérés, ce que chaque salarié perçoit — et le PDF du serveur sur les
/// mêmes paramètres que l'écran.
void main() {
  PayrollLine line(String id, String month, int net) => PayrollLine(
    month: month,
    staffMemberId: id,
    currency: 'USD',
    baseInCents: net,
    grossInCents: net,
    netInCents: net,
    formulaVersion: 2,
    frozen: true,
  );

  final snapshot = PayrollSnapshot(
    members: [
      member('m-1', lastName: 'Kabasele', firstName: 'Marie'),
      member('m-2', lastName: 'Mayala', firstName: 'Ruth'),
    ],
    contractsByMember: const {},
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {
      for (final month in ['2026-08', '2026-09'])
        month: PayrollHeader(
          id: 'p-$month',
          month: month,
          status: PayrollStatus.validated,
          validationGestureId: 'g-$month',
        ),
    },
    variables: const {},
    frozenLines: {
      '2026-08': [line('m-1', '2026-08', 20000), line('m-2', '2026-08', 15000)],
      '2026-09': [line('m-1', '2026-09', 20000), line('m-2', '2026-09', 15000)],
    },
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: const [
      PayrollDisbursement(
        id: 'd-1',
        month: '2026-09',
        staffMemberId: 'm-1',
        validationGestureId: 'g-2026-09',
        amount: Money(20000, 'USD'),
        mode: PayoutMode.cash,
        paidAt: '2026-09-28T09:00:00.000Z',
        signedRegister: true,
      ),
    ],
    schoolYears: const [(start: '2025-09-01', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );

  testAtReferenceFormats('Tableau de bord de la paie', (tester, format) async {
    final pumped = await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      child: const PayrollDashboardScreen(),
    );
    // Octobre n'a pas de paie sur cette tablette : le mois le dit.
    expect(find.text('Aucune paie pour ce mois'), findsOneWidget);

    pumped.cubit.openMonth('2026-09');
    await tester.pumpAndSettle();
    expect(find.text('Prévu et réel du mois'), findsOneWidget);
    expect(find.text('Ce que chaque salarié perçoit'), findsOneWidget);
    expect(find.text('Arriérés par salarié'), findsOneWidget);
  });

  testWidgets(
    'le PDF part avec le mois, le filtre et la recherche de l écran',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final payslips = _MockPayslips();
      when(
        () => payslips.dashboard(
          any(),
          filter: any(named: 'filter'),
          query: any(named: 'query'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      final pumped = await pumpPayrollScreen(
        tester,
        snapshot: snapshot,
        payslips: payslips,
        child: const PayrollDashboardScreen(),
      );
      pumped.cubit.openMonth('2026-09');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reste à payer'));
      await tester.enterText(find.byType(TextField).first, 'Mayala');
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      verify(
        () => payslips.dashboard(
          '2026-09',
          filter: 'OUTSTANDING',
          query: 'Mayala',
        ),
      ).called(1);
    },
  );
}
