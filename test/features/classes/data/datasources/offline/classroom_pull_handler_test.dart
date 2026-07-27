import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_pull_handler.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';

class MockClassroomOfflineRepository extends Mock
    implements ClassroomOfflineRepository {}

class MockEnrollmentReferentialDao extends Mock
    implements EnrollmentReferentialDao {}

void main() {
  late MockClassroomOfflineRepository repo;
  late MockEnrollmentReferentialDao referentialDao;
  late CurrentUserContext currentUser;
  late ClassroomPullHandler handler;

  setUp(() {
    repo = MockClassroomOfflineRepository();
    referentialDao = MockEnrollmentReferentialDao();
    currentUser = CurrentUserContext()..set('u1', schoolId: 'school-1');
    handler = ClassroomPullHandler(
      offlineRepository: repo,
      referentialDao: referentialDao,
      currentUser: currentUser,
    );
  });

  test('resource == classrooms', () {
    expect(handler.resource, 'classrooms');
  });

  test(
    'résout l\'année via le référentiel local et mappe « updated »',
    () async {
      when(
        () => referentialDao.findCurrentAcademicYearId('school-1'),
      ).thenAnswer((_) async => 'year-1');
      when(
        () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
      ).thenAnswer(
        (_) async => const Right(
          ClassroomSyncOutcome(
            classroomsUpserted: 2,
            membersUpserted: 3,
            notModified: false,
            syncedAt: 10,
          ),
        ),
      );

      final outcome = await handler.pull();

      expect(outcome.result, PullResult.updated);
      expect(outcome.upserted, 5);
      verify(() => repo.syncClassrooms(academicYearId: 'year-1')).called(1);
    },
  );

  test('un delta vide (304) → notModified', () async {
    when(
      () => referentialDao.findCurrentAcademicYearId('school-1'),
    ).thenAnswer((_) async => 'year-1');
    when(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer(
      (_) async => const Right(ClassroomSyncOutcome.notModifiedAt(10, 'cur')),
    );

    final outcome = await handler.pull();

    expect(outcome.result, PullResult.notModified);
  });

  test('référentiel indisponible → error, syncClassrooms non appelé', () async {
    when(
      () => referentialDao.findCurrentAcademicYearId('school-1'),
    ).thenAnswer((_) async => null);

    final outcome = await handler.pull();

    expect(outcome.result, PullResult.error);
    verifyNever(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    );
  });

  test('aucune session active → error', () async {
    final orphanHandler = ClassroomPullHandler(
      offlineRepository: repo,
      referentialDao: referentialDao,
      currentUser: CurrentUserContext(),
    );

    final outcome = await orphanHandler.pull();

    expect(outcome.result, PullResult.error);
  });

  test('échec du pull repo → error', () async {
    when(
      () => referentialDao.findCurrentAcademicYearId('school-1'),
    ).thenAnswer((_) async => 'year-1');
    when(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer((_) async => const Left(NetworkFailure('down')));

    final outcome = await handler.pull();

    expect(outcome.result, PullResult.error);
  });
}
