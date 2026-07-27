import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/academic_year/data/repositories/academic_year_context_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';

import '../../../offline_full_db.dart';

class MockEnrollmentPullRepository extends Mock
    implements EnrollmentPullRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late Database db;
  late EnrollmentReferentialDao referentialDao;
  late MockEnrollmentPullRepository pullRepository;
  late MockConnectivityService connectivity;
  late CurrentUserContext currentUser;
  late AcademicYearContextRepositoryImpl repository;

  setUp(() async {
    db = await openFullOfflineDb();
    referentialDao = EnrollmentReferentialDao(db);
    pullRepository = MockEnrollmentPullRepository();
    connectivity = MockConnectivityService();
    currentUser = CurrentUserContext()..set('u1', schoolId: 'school-1');
    repository = AcademicYearContextRepositoryImpl(
      referentialDao: referentialDao,
      pullRepository: pullRepository,
      connectivity: connectivity,
      currentUser: currentUser,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedYear({
    required String id,
    required bool isCurrent,
    String startDate = '2026-09-01T00:00:00Z',
  }) async {
    await db.insert('ref_academic_years', {
      'id': id,
      'name': id,
      'start_date': startDate,
      'is_current': isCurrent ? 1 : 0,
      'school_id': 'school-1',
      'synced_at': 1,
    });
  }

  group('loadCurrentContext', () {
    test('référentiel déjà local → succès sans pull', () async {
      await seedYear(id: 'ay-1', isCurrent: true);
      await db.insert('ref_school_level_groups', {
        'id': 'grp-1',
        'name': 'Primaire',
        'code': 'PRIM',
        'academic_year_id': 'ay-1',
        'display_order': 1,
        'synced_at': 1,
      });
      await db.insert('ref_school_levels', {
        'id': 'lvl-1',
        'name': '1ère Primaire',
        'code': 'P1',
        'level_group_id': 'grp-1',
        'display_order': 1,
        'split_into_classrooms': 0,
        'synced_at': 1,
      });

      final result = await repository.loadCurrentContext();

      expect(result.isRight(), isTrue);
      final context = result.getOrElse(() => throw StateError('unreachable'));
      expect(context.academicYear.id, 'ay-1');
      expect(context.schoolLevelGroups, hasLength(1));
      expect(context.schoolLevelGroups.single.levels.single.id, 'lvl-1');
      verifyNever(() => pullRepository.syncReferential());
    });

    test(
      'référentiel absent + en ligne → pull déclenché puis succès',
      () async {
        when(() => connectivity.isOnline()).thenAnswer((_) async => true);
        when(() => pullRepository.syncReferential()).thenAnswer((_) async {
          await seedYear(id: 'ay-1', isCurrent: true);
          return const Right(
            EnrollmentPullOutcome(upserted: 1, notModified: false, syncedAt: 1),
          );
        });

        final result = await repository.loadCurrentContext();

        expect(result.isRight(), isTrue);
        verify(() => pullRepository.syncReferential()).called(1);
      },
    );

    test('référentiel absent + hors ligne → NetworkFailure', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);

      final result = await repository.loadCurrentContext();

      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      verifyNever(() => pullRepository.syncReferential());
    });

    test('échec du pull → Failure propagée', () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => true);
      const failure = ServerFailure('boom');
      when(
        () => pullRepository.syncReferential(),
      ).thenAnswer((_) async => const Left(failure));

      final result = await repository.loadCurrentContext();

      expect(result.fold((f) => f, (_) => null), same(failure));
    });

    test('aucune session active → AuthFailure', () async {
      final orphanRepository = AcademicYearContextRepositoryImpl(
        referentialDao: referentialDao,
        pullRepository: pullRepository,
        connectivity: connectivity,
        currentUser: CurrentUserContext(),
      );

      final result = await orphanRepository.loadCurrentContext();

      expect(result.fold((f) => f, (_) => null), isA<AuthFailure>());
    });
  });

  group('loadPreviousContext', () {
    test('pas d\'année antérieure → Right(null), pas un échec', () async {
      await seedYear(id: 'ay-1', isCurrent: true);

      final result = await repository.loadPreviousContext();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw StateError('unreachable')), isNull);
    });

    test('année antérieure connue → contexte résolu', () async {
      await seedYear(id: 'ay-cur', isCurrent: true);
      await seedYear(
        id: 'ay-prev',
        isCurrent: false,
        startDate: '2025-09-01T00:00:00Z',
      );

      final result = await repository.loadPreviousContext();

      final context = result.getOrElse(() => throw StateError('unreachable'));
      expect(context?.academicYear.id, 'ay-prev');
    });
  });

  test('markSchoolLevelSplit délègue au DAO référentiel', () async {
    await seedYear(id: 'ay-1', isCurrent: true);
    await db.insert('ref_school_level_groups', {
      'id': 'grp-1',
      'name': 'Primaire',
      'code': 'PRIM',
      'academic_year_id': 'ay-1',
      'display_order': 1,
      'synced_at': 1,
    });
    await db.insert('ref_school_levels', {
      'id': 'lvl-1',
      'name': '1ère Primaire',
      'code': 'P1',
      'level_group_id': 'grp-1',
      'display_order': 1,
      'split_into_classrooms': 0,
      'synced_at': 1,
    });

    await repository.markSchoolLevelSplit('lvl-1');

    final level = (await db.query('ref_school_levels')).single;
    expect(level['split_into_classrooms'], 1);
  });
}
