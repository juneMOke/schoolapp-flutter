import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_pull_outcome.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_pull_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/sync_finance_pulls_use_case.dart';

class MockFinancePullRepository extends Mock implements FinancePullRepository {}

class MockCredentialsProbe extends Mock implements SessionCredentialsProbe {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockFinancePullRepository repository;
  late MockCredentialsProbe credentialsProbe;
  late MockConnectivityService connectivity;
  late SyncFinancePullsUseCase useCase;

  setUp(() {
    repository = MockFinancePullRepository();
    credentialsProbe = MockCredentialsProbe();
    connectivity = MockConnectivityService();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => true);
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    useCase = SyncFinancePullsUseCase(
      repository,
      credentialsProbe,
      connectivity,
    );
  });

  Either<Failure, FinancePullOutcome> updated(int upserted) => Right(
    FinancePullOutcome(
      upserted: upserted,
      notModified: false,
      syncedAt: 10000,
      cursor: 'wWM1',
    ),
  );

  Either<Failure, FinancePullOutcome> notModified() =>
      const Right(FinancePullOutcome.notModifiedAt(10000, 'wWM0'));

  test(
    'ordre PORTEUR : les créances (vérité du grand-livre) sont tirées AVANT les '
    'paiements (les événements qui s\'y imputent)',
    () async {
      final order = <String>[];
      when(() => repository.syncStudentCharges()).thenAnswer((_) async {
        order.add('charges');
        return updated(3);
      });
      when(() => repository.syncPayments()).thenAnswer((_) async {
        order.add('payments');
        return updated(2);
      });

      final report = await useCase();

      expect(order, ['charges', 'payments']);
      expect(report.updated, 2);
      expect(report.notModified, 0);
      expect(report.failed, 0);
    },
  );

  test(
    'bilan : un 304 par ressource compte en notModified, pas en échec',
    () async {
      when(
        () => repository.syncStudentCharges(),
      ).thenAnswer((_) async => notModified());
      when(
        () => repository.syncPayments(),
      ).thenAnswer((_) async => notModified());

      final report = await useCase();

      expect(report.notModified, 2);
      expect(report.updated, 0);
      expect(report.failed, 0);
    },
  );

  test(
    'DÉPENDANCE, pas simple ordre : créances KO → les paiements ne sont même '
    'pas tentés (les avancer sur un miroir périmé fait RÉENCAISSER)',
    () async {
      when(
        () => repository.syncStudentCharges(),
      ).thenAnswer((_) async => const Left(ServerFailure('boom')));
      when(() => repository.syncPayments()).thenAnswer((_) async => updated(2));

      final report = await useCase();

      verifyNever(() => repository.syncPayments());
      expect(report.failed, 1);
      expect(report.skipped, 1);
      expect(report.updated, 0);
    },
  );

  test('best-effort : l\'échec des PAIEMENTS ne remonte pas (le cache reste en '
      'l\'état) — le miroir des créances, lui, est bien à jour', () async {
    when(
      () => repository.syncStudentCharges(),
    ).thenAnswer((_) async => updated(3));
    when(
      () => repository.syncPayments(),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final report = await useCase();

    expect(report.updated, 1);
    expect(report.failed, 1);
    expect(report.skipped, 0);
  });

  test('gate connectivité : hors-ligne, aucun appel réseau et les deux '
      'ressources sont comptées "skipped"', () async {
    when(
      () => repository.syncStudentCharges(),
    ).thenAnswer((_) async => updated(3));
    when(() => repository.syncPayments()).thenAnswer((_) async => updated(2));
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);

    final report = await useCase();

    verifyNever(() => repository.syncStudentCharges());
    verifyNever(() => repository.syncPayments());
    expect(report.skipped, 2);
    expect(report.updated, 0);
    expect(report.failed, 0);
  });

  test('gate crédentiels : sans session authentifiable, aucun appel réseau et '
      'les deux ressources sont comptées "skipped"', () async {
    when(
      () => repository.syncStudentCharges(),
    ).thenAnswer((_) async => updated(3));
    when(() => repository.syncPayments()).thenAnswer((_) async => updated(2));
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => false);

    final report = await useCase();

    verifyNever(() => repository.syncStudentCharges());
    verifyNever(() => repository.syncPayments());
    expect(report.skipped, 2);
    expect(report.updated, 0);
    expect(report.failed, 0);
  });

  test('gate crédentiels : une sonde en échec ne bloque pas la synchro '
      '(fail-open, même politique que SyncStatusCubit)', () async {
    when(
      () => repository.syncStudentCharges(),
    ).thenAnswer((_) async => updated(3));
    when(() => repository.syncPayments()).thenAnswer((_) async => updated(2));
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenThrow(Exception('storage indisponible'));

    final report = await useCase();

    verify(() => repository.syncStudentCharges()).called(1);
    verify(() => repository.syncPayments()).called(1);
    expect(report.updated, 2);
  });
}
