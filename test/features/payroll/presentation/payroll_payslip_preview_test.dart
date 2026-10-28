import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/network_status_cubit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_agent_page.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

class _MockPayslips extends Mock implements PayslipRepository {}

class _MockConnectivity extends Mock implements ConnectivityService {}

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
  late StaffSyncSignals signals;
  late MockPayrollRepository repository;

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
      child: const PayrollAgentScreen(agentId: 'm-1', entryMonth: '2026-10'),
    );
    signals = pumped.signals;
    repository = pumped.repository;
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

    // La file part d'abord : le PDF doit voir les dernières saisies.
    verifyInOrder([
      () => signals.flush(),
      () => payslips.payslipPreview('2026-10', 'm-1'),
    ]);
    verifyNever(() => payslips.payslip(any(), any()));
  });

  for (final (name, failure, message) in [
    (
      'agent hors du livre',
      const ApiValidationFailure(
        code: ApiErrorCode.unprocessable,
        detailCode: 'STAFF_NOT_ON_PAYROLL',
      ),
      "Cet agent n'a pas de contrat qui le paie ce mois-là.",
    ),
    (
      'droit absent (403)',
      const UnauthorizedFailure(),
      'Votre compte n\'a pas le droit de faire ce geste.',
    ),
  ]) {
    testWidgets('refus nommé : $name', (tester) async {
      await openPayslips(tester, snapshotOf());
      when(
        () => payslips.payslipPreview(any(), any()),
      ).thenAnswer((_) async => Left(failure));

      await tester.tap(find.text('Bulletin provisoire (PDF)'));
      await tester.pumpAndSettle();

      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('hors ligne : le bouton se désactive et dit pourquoi', (
    tester,
  ) async {
    final connectivity = _MockConnectivity();
    when(connectivity.isOnline).thenAnswer((_) async => false);
    when(
      () => connectivity.onStatusChange,
    ).thenAnswer((_) => const Stream.empty());
    GetIt.instance.registerFactory<NetworkStatusCubit>(
      () => NetworkStatusCubit(connectivity),
    );
    addTearDown(() => GetIt.instance.unregister<NetworkStatusCubit>());

    await openPayslips(tester, snapshotOf());

    expect(
      find.text(
        'Disponible en ligne seulement : le provisoire est rendu par le serveur.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Bulletin provisoire (PDF)'));
    await tester.pumpAndSettle();
    verifyNever(() => payslips.payslipPreview(any(), any()));
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
    // La paie est relue (tirée puis lue), jamais de scellé demandé d'office.
    verifyInOrder([
      () => payslips.payslipPreview('2026-10', 'm-1'),
      () => signals.pull(),
    ]);
    verify(() => repository.load()).called(greaterThan(1));
    verifyNever(() => payslips.payslip(any(), any()));
  });

  testWidgets('validée : le bulletin scellé à la place du provisoire', (
    tester,
  ) async {
    await openPayslips(tester, snapshotOf(status: PayrollStatus.validated));

    expect(find.text('Bulletin provisoire (PDF)'), findsNothing);
    expect(find.text('Télécharger le PDF'), findsOneWidget);
  });
}
