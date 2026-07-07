import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_academic_year.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_pull_handler.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

class MockClassroomOfflineRepository extends Mock
    implements ClassroomOfflineRepository {}

class MockBootstrapLocalRepository extends Mock
    implements BootstrapLocalRepository {}

Bootstrap bootstrapWith(String yearId) => Bootstrap(
  schoolId: 'school-1',
  academicYear: BootstrapAcademicYear(
    id: yearId,
    name: '2026-2027',
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2027, 6, 30),
    current: true,
  ),
  schoolLevelGroups: const [],
);

void main() {
  late MockClassroomOfflineRepository repo;
  late MockBootstrapLocalRepository bootstrap;
  late ClassroomPullHandler handler;

  setUp(() {
    repo = MockClassroomOfflineRepository();
    bootstrap = MockBootstrapLocalRepository();
    handler = ClassroomPullHandler(
      offlineRepository: repo,
      bootstrapRepository: bootstrap,
      bootstrapKey: 'bootstrap_payload',
    );
  });

  test('resource == classrooms', () {
    expect(handler.resource, 'classrooms');
  });

  test('résout l\'année via le bootstrap local et mappe « updated »', () async {
    when(
      () => bootstrap.getStoredBootstrap(any()),
    ).thenAnswer((_) async => Right(bootstrapWith('year-1')));
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
  });

  test('un delta vide (304) → notModified', () async {
    when(
      () => bootstrap.getStoredBootstrap(any()),
    ).thenAnswer((_) async => Right(bootstrapWith('year-1')));
    when(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer(
      (_) async => const Right(ClassroomSyncOutcome.notModifiedAt(10, 'cur')),
    );

    final outcome = await handler.pull();

    expect(outcome.result, PullResult.notModified);
  });

  test('bootstrap indisponible → error, syncClassrooms non appelé', () async {
    when(
      () => bootstrap.getStoredBootstrap(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('no bootstrap')));

    final outcome = await handler.pull();

    expect(outcome.result, PullResult.error);
    verifyNever(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    );
  });

  test('échec du pull repo → error', () async {
    when(
      () => bootstrap.getStoredBootstrap(any()),
    ).thenAnswer((_) async => Right(bootstrapWith('year-1')));
    when(
      () => repo.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer((_) async => const Left(NetworkFailure('down')));

    final outcome = await handler.pull();

    expect(outcome.result, PullResult.error);
  });
}
