import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_transfer_pull_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_transfer_pull_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classroom_referential_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';

class _MockRepo extends Mock implements ClassroomOfflineRepository {}

class _MockTransferRepo extends Mock
    implements ClassroomTransferPullRepository {}

class _MockDao extends Mock implements EnrollmentReferentialDao {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockProbe extends Mock implements SessionCredentialsProbe {}

/// ADR-015 §6-D — `classroom.transfers` n'avait AUCUN déclencheur de montage :
/// il ne descendait que par le `PullCoordinator`, lui-même déclenché par la
/// seule transition hors-ligne → en ligne. Sur une tablette démarrée déjà
/// connectée — le cas nominal — son marqueur de bootstrap n'était jamais posé,
/// et l'onglet Présence de la fiche élève restait à vie sur « Synchronisation
/// en attente ».
void main() {
  late _MockRepo repo;
  late _MockTransferRepo transferRepo;
  late _MockDao dao;
  late _MockConnectivity connectivity;
  late _MockProbe probe;

  setUp(() {
    repo = _MockRepo();
    transferRepo = _MockTransferRepo();
    dao = _MockDao();
    connectivity = _MockConnectivity();
    probe = _MockProbe();

    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(() => probe.canAuthenticate()).thenAnswer((_) async => true);
    when(
      () => dao.findCurrentAcademicYearId(any()),
    ).thenAnswer((_) async => 'ay-1');
    when(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer(
      (_) async => const Right(
        ClassroomSyncOutcome(
          classroomsUpserted: 0,
          membersUpserted: 0,
          notModified: true,
          syncedAt: 0,
        ),
      ),
    );
    when(() => transferRepo.syncTransfers()).thenAnswer(
      (_) async => const Right(
        ClassroomTransferPullOutcome(
          upserted: 0,
          notModified: true,
          bootstrapComplete: true,
          syncedAt: 0,
        ),
      ),
    );
  });

  SyncClassroomReferentialUseCase build() => SyncClassroomReferentialUseCase(
    repository: repo,
    transferRepository: transferRepo,
    referentialDao: dao,
    currentUser: CurrentUserContext()..set('u-1', schoolId: 'school-1'),
    credentialsProbe: probe,
    connectivity: connectivity,
  );

  test('les transferts sont tirés APRÈS les classes, jamais avant', () async {
    await build().call();

    verifyInOrder([
      () => repo.syncClassrooms(academicYearId: 'ay-1'),
      () => transferRepo.syncTransfers(),
    ]);
  });

  test('hors ligne : aucun appel, ni classes ni transferts', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);

    expect(await build().call(), isFalse);
    verifyNever(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    );
    verifyNever(() => transferRepo.syncTransfers());
  });

  test('sans année courante résolue : aucun appel', () async {
    when(
      () => dao.findCurrentAcademicYearId(any()),
    ).thenAnswer((_) async => null);

    expect(await build().call(), isFalse);
    verifyNever(() => transferRepo.syncTransfers());
  });

  test(
    'un échec des transferts ne fait pas échouer l\'hydratation des classes',
    () async {
      when(
        () => transferRepo.syncTransfers(),
      ).thenAnswer((_) async => const Left(NetworkFailure('boom')));

      expect(await build().call(), isTrue);
      verify(() => transferRepo.syncTransfers()).called(1);
    },
  );

  test(
    'un transfert qui LÈVE est isolé : le verdict reste celui des classes',
    () async {
      when(() => transferRepo.syncTransfers()).thenThrow(StateError('boom'));

      expect(await build().call(), isTrue);
    },
  );

  test('un échec des classes n\'empêche pas le cycle des transferts', () async {
    when(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer((_) async => const Left(NetworkFailure('boom')));

    expect(await build().call(), isFalse);
    verify(() => transferRepo.syncTransfers()).called(1);
  });
}
