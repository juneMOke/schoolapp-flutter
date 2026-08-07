import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/attendance_pull_outcome.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_pull_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_attendance_pull_usecase.dart';

class MockAttendancePullRepository extends Mock
    implements AttendancePullRepository {}

class MockCredentialsProbe extends Mock implements SessionCredentialsProbe {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockAttendancePullRepository repository;
  late MockCredentialsProbe credentialsProbe;
  late MockConnectivityService connectivity;
  late SyncAttendancePullUseCase useCase;

  const outcome = AttendancePullOutcome(
    upserted: 1,
    notModified: false,
    bootstrapComplete: true,
    syncedAt: 10000,
  );

  setUp(() {
    repository = MockAttendancePullRepository();
    credentialsProbe = MockCredentialsProbe();
    connectivity = MockConnectivityService();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => true);
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    useCase = SyncAttendancePullUseCase(
      repository,
      credentialsProbe,
      connectivity,
    );
  });

  test('authentifié : délègue au repository', () async {
    when(
      () => repository.syncAttendance(),
    ).thenAnswer((_) async => const Right(outcome));

    final result = await useCase();

    expect(result, const Right(outcome));
    verify(() => repository.syncAttendance()).called(1);
  });

  test('gate connectivité : hors-ligne, le repository n\'est jamais appelé et '
      'un NetworkFailure est retourné', () async {
    when(
      () => repository.syncAttendance(),
    ).thenAnswer((_) async => const Right(outcome));
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);

    final result = await useCase();

    verifyNever(() => repository.syncAttendance());
    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('devrait être un Left'),
    );
  });

  test('gate crédentiels : sans session authentifiable, le repository n\'est '
      'jamais appelé et un AuthFailure est retourné', () async {
    when(
      () => repository.syncAttendance(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => false);

    final result = await useCase();

    verifyNever(() => repository.syncAttendance());
    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<AuthFailure>()),
      (_) => fail('devrait être un Left'),
    );
  });

  test('gate crédentiels : une sonde en échec ne bloque pas l\'hydratation '
      '(fail-open, même politique que SyncStatusCubit)', () async {
    when(
      () => repository.syncAttendance(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenThrow(Exception('storage indisponible'));

    final result = await useCase();

    verify(() => repository.syncAttendance()).called(1);
    expect(result, const Right(outcome));
  });
}
