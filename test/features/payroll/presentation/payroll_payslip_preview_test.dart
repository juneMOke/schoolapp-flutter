import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

class _MockPayslips extends Mock implements PayslipRepository {}

/// Le bulletin provisoire (P8) : rendu par le serveur, agent par agent, en
/// ligne seulement ; jamais composé sur la tablette, jamais de recueil.
void main() {
  PayrollSnapshot snapshotOf({PayrollStatus? status}) => PayrollSnapshot(
    members: [member('m-1', lastName: 'Mayala', firstName: 'Ruth')],
    contractsByMember: {
      'm-1': [contract('m-1')],
    },
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {
      if (status != null)
        '2026-10': PayrollHeader(
          id: 'p-10',
          month: '2026-10',
          status: status,
          validationGestureId: status == PayrollStatus.validated ? 'g' : null,
        ),
    },
    variables: const {},
    frozenLines: {
      if (status == PayrollStatus.validated)
        '2026-10': [
          const PayrollLine(
            month: '2026-10',
            staffMemberId: 'm-1',
            currency: 'USD',
            baseInCents: 35000,
            grossInCents: 35000,
            netInCents: 35000,
            frozen: true,
          ),
        ],
    },
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: const [],
    schoolYears: const [(start: '2026-09-01', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );

  late _MockPayslips payslips;

  Future<void> openPayslips(
    WidgetTester tester,
    PayrollSnapshot snapshot,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    payslips = _MockPayslips();
    final pumped = await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      payslips: payslips,
    );
    pumped.cubit.setTab(PayrollTab.payslips);
    await tester.pumpAndSettle();
  }

  testWidgets('brouillon : le provisoire vient du serveur, sans recueil', (
    tester,
  ) async {
    await openPayslips(tester, snapshotOf());
    when(
      () => payslips.payslipPreview(any(), any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    expect(find.text('Tous les bulletins (PDF)'), findsNothing);
    await tester.tap(find.text('Bulletin provisoire (PDF)'));
    await tester.pumpAndSettle();

    verify(() => payslips.payslipPreview('2026-10', 'm-1')).called(1);
    verifyNever(() => payslips.payslip(any(), any()));
  });

  testWidgets('validée entre-temps : la paie se relit, le scellé est proposé', (
    tester,
  ) async {
    await openPayslips(tester, snapshotOf());
    when(() => payslips.payslipPreview(any(), any())).thenAnswer(
      (_) async => const Left(
        ApiValidationFailure(
          code: ApiErrorCode.unprocessable,
          detailCode: 'PAYROLL_ALREADY_VALIDATED',
        ),
      ),
    );

    await tester.tap(find.text('Bulletin provisoire (PDF)'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'La paie vient d\'être validée : demandez désormais le bulletin scellé.',
      ),
      findsOneWidget,
    );
    // Jamais de scellé demandé d'office.
    verifyNever(() => payslips.payslip(any(), any()));
  });

  testWidgets('validée : le scellé, et le recueil du mois', (tester) async {
    await openPayslips(tester, snapshotOf(status: PayrollStatus.validated));

    expect(find.text('Bulletin provisoire (PDF)'), findsNothing);
    expect(find.text('Tous les bulletins (PDF)'), findsWidgets);
  });
}
