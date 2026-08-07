import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_handler.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';

class MockEnrollmentPullRepository extends Mock
    implements EnrollmentPullRepository {}

void main() {
  late MockEnrollmentPullRepository repo;

  setUp(() {
    repo = MockEnrollmentPullRepository();
  });

  test('les cinq ressources sont distinctes et alignées sur sync_meta', () {
    final resources = [
      EnrollmentPullHandler.referential(repo).resource,
      EnrollmentPullHandler.reenrollmentCohort(repo).resource,
      EnrollmentPullHandler.preEnrollments(repo).resource,
      EnrollmentPullHandler.enrollmentSnapshots(repo).resource,
      EnrollmentPullHandler.enrollmentDelta(repo).resource,
    ];

    expect(resources.toSet(), hasLength(5));
    // Ordre PORTEUR : snapshots (INSERT hydratant) avant delta (UPDATE-only).
    expect(resources, [
      EnrollmentPullRepositoryImpl.referentialResource,
      EnrollmentPullRepositoryImpl.cohortResource,
      EnrollmentPullRepositoryImpl.preEnrollmentsResource,
      EnrollmentPullRepositoryImpl.snapshotsResource,
      EnrollmentPullRepositoryImpl.deltaResource,
    ]);
  });

  test('délègue chaque ressource à la bonne méthode du repository', () async {
    const outcome = EnrollmentPullOutcome(
      upserted: 2,
      notModified: false,
      syncedAt: 10,
    );
    when(
      () => repo.syncReferential(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => repo.syncReenrollmentCohort(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => repo.syncPreEnrollments(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => repo.syncEnrollmentSnapshots(),
    ).thenAnswer((_) async => const Right(outcome));
    when(
      () => repo.syncEnrollmentDelta(),
    ).thenAnswer((_) async => const Right(outcome));

    await EnrollmentPullHandler.referential(repo).pull();
    await EnrollmentPullHandler.reenrollmentCohort(repo).pull();
    await EnrollmentPullHandler.preEnrollments(repo).pull();
    await EnrollmentPullHandler.enrollmentSnapshots(repo).pull();
    await EnrollmentPullHandler.enrollmentDelta(repo).pull();

    verify(() => repo.syncReferential()).called(1);
    verify(() => repo.syncReenrollmentCohort()).called(1);
    verify(() => repo.syncPreEnrollments()).called(1);
    verify(() => repo.syncEnrollmentSnapshots()).called(1);
    verify(() => repo.syncEnrollmentDelta()).called(1);
  });

  test('Right(upsert) → PullOutcome.updated avec le compte', () async {
    when(() => repo.syncReferential()).thenAnswer(
      (_) async => const Right(
        EnrollmentPullOutcome(upserted: 5, notModified: false, syncedAt: 10),
      ),
    );

    final outcome = await EnrollmentPullHandler.referential(repo).pull();

    expect(outcome.result, PullResult.updated);
    expect(outcome.upserted, 5);
  });

  test('Right(notModified) → PullOutcome.notModified', () async {
    when(() => repo.syncPreEnrollments()).thenAnswer(
      (_) async => const Right(EnrollmentPullOutcome.notModifiedAt(10, 'cur')),
    );

    final outcome = await EnrollmentPullHandler.preEnrollments(repo).pull();

    expect(outcome.result, PullResult.notModified);
  });

  test('Left(failure) → PullOutcome.error (jamais levé)', () async {
    when(() => repo.syncEnrollmentDelta()).thenAnswer(
      (_) async => const Left(NetworkFailure('Network error occurred')),
    );

    final outcome = await EnrollmentPullHandler.enrollmentDelta(repo).pull();

    expect(outcome.result, PullResult.error);
    expect(outcome.error, contains('Network error'));
  });
}
