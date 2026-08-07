import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';

class MockEnrollmentPullRepository extends Mock
    implements EnrollmentPullRepository {}

class MockCredentialsProbe extends Mock implements SessionCredentialsProbe {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockEnrollmentPullRepository repository;
  late MockCredentialsProbe credentialsProbe;
  late MockConnectivityService connectivity;
  late SyncEnrollmentPullsUseCase useCase;

  const outcome = EnrollmentPullOutcome(
    upserted: 1,
    notModified: false,
    syncedAt: 10000,
    cursor: 'wWM1',
  );

  void stubAllPullsSucceed() {
    when(
      () => repository.syncReferential(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => repository.syncReenrollmentCohort(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => repository.syncPreEnrollments(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => repository.syncEnrollmentSnapshots(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => repository.syncEnrollmentDelta(),
    ).thenAnswer((_) async => const Right(outcome));
  }

  setUp(() {
    repository = MockEnrollmentPullRepository();
    credentialsProbe = MockCredentialsProbe();
    connectivity = MockConnectivityService();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => true);
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    useCase = SyncEnrollmentPullsUseCase(
      repository,
      credentialsProbe,
      connectivity,
    );
  });

  test('authentifié : les cinq ressources sont tirées et agrégées', () async {
    stubAllPullsSucceed();

    final report = await useCase();

    expect(report.updated, 5);
    expect(report.notModified, 0);
    expect(report.failed, 0);
    verify(() => repository.syncReferential()).called(1);
    verify(() => repository.syncEnrollmentDelta()).called(1);
  });

  test('gate connectivité : hors-ligne, aucune des cinq ressources n\'est '
      'appelée (aucune requête HTTP émise)', () async {
    stubAllPullsSucceed();
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);

    final report = await useCase();

    verifyNever(() => repository.syncReferential());
    verifyNever(() => repository.syncReenrollmentCohort());
    verifyNever(() => repository.syncPreEnrollments());
    verifyNever(() => repository.syncEnrollmentSnapshots());
    verifyNever(() => repository.syncEnrollmentDelta());
    expect(report.updated, 0);
    expect(report.notModified, 0);
    expect(report.failed, 0);
  });

  test('gate crédentiels : sans session authentifiable, aucune des cinq '
      'ressources n\'est appelée', () async {
    stubAllPullsSucceed();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => false);

    final report = await useCase();

    verifyNever(() => repository.syncReferential());
    verifyNever(() => repository.syncReenrollmentCohort());
    verifyNever(() => repository.syncPreEnrollments());
    verifyNever(() => repository.syncEnrollmentSnapshots());
    verifyNever(() => repository.syncEnrollmentDelta());
    expect(report.updated, 0);
    expect(report.notModified, 0);
    expect(report.failed, 0);
  });

  test('gate crédentiels : une sonde en échec ne bloque pas l\'hydratation '
      '(fail-open, même politique que SyncStatusCubit)', () async {
    stubAllPullsSucceed();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenThrow(Exception('storage indisponible'));

    final report = await useCase();

    verify(() => repository.syncReferential()).called(1);
    verify(() => repository.syncEnrollmentDelta()).called(1);
    expect(report.updated, 5);
  });
}
