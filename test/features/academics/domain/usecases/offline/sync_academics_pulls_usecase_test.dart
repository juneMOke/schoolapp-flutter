import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/cours_pull_outcome.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/offline/sync_academics_pulls_usecase.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/offline/ref_pull_outcome.dart';

class MockSchedulePullRepositoryImpl extends Mock
    implements SchedulePullRepositoryImpl {}

class MockAcademicsCoursPullRepositoryImpl extends Mock
    implements AcademicsCoursPullRepositoryImpl {}

class MockAcademicsMetierPullRepositoryImpl extends Mock
    implements AcademicsMetierPullRepositoryImpl {}

class MockGradesReferentialPullRepositoryImpl extends Mock
    implements GradesReferentialPullRepositoryImpl {}

class MockCredentialsProbe extends Mock implements SessionCredentialsProbe {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockSchedulePullRepositoryImpl schedulePull;
  late MockAcademicsCoursPullRepositoryImpl coursPull;
  late MockAcademicsMetierPullRepositoryImpl metierPull;
  late MockGradesReferentialPullRepositoryImpl gradesReferentialPull;
  late MockCredentialsProbe credentialsProbe;
  late MockConnectivityService connectivity;
  late SyncAcademicsPullsUseCase useCase;

  const refOutcome = RefPullOutcome(
    upserted: 1,
    notModified: false,
    bootstrapComplete: true,
    syncedAt: 10000,
    cursor: 'wWM1',
  );
  const coursOutcome = CoursPullOutcome(
    upserted: 1,
    notModified: false,
    bootstrapComplete: true,
    syncedAt: 10000,
  );
  const deltaOutcome = AcademicsDeltaPullOutcome(
    upserted: 1,
    notModified: false,
    bootstrapComplete: true,
    syncedAt: 10000,
  );

  void stubAllPullsSucceed() {
    when(
      () => schedulePull.syncTimeSlots(),
    ).thenAnswer((_) async => const Right(refOutcome));
    when(
      () => schedulePull.syncSessions(),
    ).thenAnswer((_) async => const Right(refOutcome));
    when(
      () => coursPull.syncCours(),
    ).thenAnswer((_) async => const Right(coursOutcome));
    when(
      () => gradesReferentialPull.syncGradesReferential(),
    ).thenAnswer((_) async => const Right(coursOutcome));
    when(
      () => metierPull.syncEvaluations(),
    ).thenAnswer((_) async => const Right(deltaOutcome));
    when(
      () => metierPull.syncNotes(),
    ).thenAnswer((_) async => const Right(deltaOutcome));
  }

  setUp(() {
    schedulePull = MockSchedulePullRepositoryImpl();
    coursPull = MockAcademicsCoursPullRepositoryImpl();
    metierPull = MockAcademicsMetierPullRepositoryImpl();
    gradesReferentialPull = MockGradesReferentialPullRepositoryImpl();
    credentialsProbe = MockCredentialsProbe();
    connectivity = MockConnectivityService();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => true);
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    useCase = SyncAcademicsPullsUseCase(
      schedulePullRepository: schedulePull,
      coursPullRepository: coursPull,
      metierPullRepository: metierPull,
      gradesReferentialPullRepository: gradesReferentialPull,
      credentialsProbe: credentialsProbe,
      connectivity: connectivity,
    );
  });

  test(
    'authentifié : les pulls partent dans l\'ordre PORTEUR (emploi du temps → '
    'cours → grades-referential → métier)',
    () async {
      stubAllPullsSucceed();

      await useCase();

      verify(() => schedulePull.syncTimeSlots()).called(1);
      verify(() => schedulePull.syncSessions()).called(1);
      verify(() => coursPull.syncCours()).called(1);
      verify(() => gradesReferentialPull.syncGradesReferential()).called(1);
      verify(() => metierPull.syncEvaluations()).called(1);
      verify(() => metierPull.syncNotes()).called(1);
    },
  );

  test('gate connectivité : hors-ligne, aucun des pulls n\'est déclenché '
      '(aucune requête HTTP émise)', () async {
    stubAllPullsSucceed();
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);

    await useCase();

    verifyNever(() => schedulePull.syncTimeSlots());
    verifyNever(() => schedulePull.syncSessions());
    verifyNever(() => coursPull.syncCours());
    verifyNever(() => gradesReferentialPull.syncGradesReferential());
    verifyNever(() => metierPull.syncEvaluations());
    verifyNever(() => metierPull.syncNotes());
  });

  test('gate crédentiels : sans session authentifiable, aucun des pulls '
      'n\'est déclenché', () async {
    stubAllPullsSucceed();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => false);

    await useCase();

    verifyNever(() => schedulePull.syncTimeSlots());
    verifyNever(() => schedulePull.syncSessions());
    verifyNever(() => coursPull.syncCours());
    verifyNever(() => gradesReferentialPull.syncGradesReferential());
    verifyNever(() => metierPull.syncEvaluations());
    verifyNever(() => metierPull.syncNotes());
  });

  test('gate crédentiels : une sonde en échec ne bloque pas l\'hydratation '
      '(fail-open, même politique que SyncStatusCubit)', () async {
    stubAllPullsSucceed();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenThrow(Exception('storage indisponible'));

    await useCase();

    verify(() => schedulePull.syncTimeSlots()).called(1);
    verify(() => metierPull.syncNotes()).called(1);
  });
}
