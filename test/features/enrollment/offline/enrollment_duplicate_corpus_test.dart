import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_duplicate_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/parent_search_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_offline_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/known_student_identity.dart';

class MockEnrollmentReadDao extends Mock implements EnrollmentReadDao {}

class MockEnrollmentDraftDao extends Mock implements EnrollmentDraftDao {}

class MockEnrollmentSeedDao extends Mock implements EnrollmentSeedDao {}

class MockParentSearchDao extends Mock implements ParentSearchDao {}

class MockEnrollmentDuplicateDao extends Mock
    implements EnrollmentDuplicateDao {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockSyncEngine extends Mock implements SyncEngine {}

KnownStudentIdentity _known(
  String studentId,
  EnrollmentDuplicateSource source,
) => KnownStudentIdentity(
  studentId: studentId,
  source: source,
  identity: const EnrollmentIdentity(
    lastName: 'Mukendi',
    firstName: 'Jean',
    surname: 'Kabeya',
    dateOfBirth: '2015-03-04',
  ),
);

/// Assemblage du corpus de la sonde de doublon : c'est le repository qui
/// résout l'année et concatène les deux sources — le usecase, lui, ne fait que
/// rapprocher.
void main() {
  late MockEnrollmentSeedDao seedDao;
  late MockEnrollmentDuplicateDao duplicateDao;
  late EnrollmentOfflineRepositoryImpl repository;

  setUp(() {
    seedDao = MockEnrollmentSeedDao();
    duplicateDao = MockEnrollmentDuplicateDao();
    repository = EnrollmentOfflineRepositoryImpl(
      readDao: MockEnrollmentReadDao(),
      draftDao: MockEnrollmentDraftDao(),
      seedDao: seedDao,
      parentSearchDao: MockParentSearchDao(),
      duplicateDao: duplicateDao,
      idGenerator: MockIdGenerator(),
      syncEngine: MockSyncEngine(),
    );

    when(
      () => duplicateDao.currentYearIdentities(
        academicYearId: any(named: 'academicYearId'),
        excludedStudentId: any(named: 'excludedStudentId'),
        excludedEnrollmentId: any(named: 'excludedEnrollmentId'),
      ),
    ).thenAnswer(
      (_) async => [
        _known('dossier', EnrollmentDuplicateSource.currentYearDossier),
      ],
    );
    when(
      () => duplicateDao.previousYearCohortIdentities(
        excludedStudentId: any(named: 'excludedStudentId'),
      ),
    ).thenAnswer(
      (_) async => [
        _known('cohorte', EnrollmentDuplicateSource.previousYearCohort),
      ],
    );
  });

  Future<List<KnownStudentIdentity>> load({String? academicYearId}) async {
    final result = await repository.loadDuplicateProbeCorpus(
      studentId: 'self',
      enrollmentId: 'self-e',
      academicYearId: academicYearId,
    );
    return result.getOrElse(() => throw StateError('attendu Right'));
  }

  test(
    'année fournie : elle part telle quelle, sans être re-résolue',
    () async {
      final corpus = await load(academicYearId: 'ay-2026');

      expect([for (final k in corpus) k.studentId], ['dossier', 'cohorte']);
      verify(
        () => duplicateDao.currentYearIdentities(
          academicYearId: 'ay-2026',
          excludedStudentId: 'self',
          excludedEnrollmentId: 'self-e',
        ),
      ).called(1);
      verifyNever(() => seedDao.findCurrentAcademicYearId());
    },
  );

  test(
    'année absente : elle est résolue sur l\'année courante locale',
    () async {
      when(
        () => seedDao.findCurrentAcademicYearId(),
      ).thenAnswer((_) async => 'ay-courante');

      await load();

      verify(
        () => duplicateDao.currentYearIdentities(
          academicYearId: 'ay-courante',
          excludedStudentId: 'self',
          excludedEnrollmentId: 'self-e',
        ),
      ).called(1);
    },
  );

  test(
    'année non résolue : les dossiers sont sautés, la cohorte parle seule',
    () async {
      when(
        () => seedDao.findCurrentAcademicYearId(),
      ).thenAnswer((_) async => null);

      final corpus = await load();

      expect([for (final k in corpus) k.studentId], ['cohorte']);
      // Interroger sans scope mélangerait les exercices — et une autre école
      // avec eux, `enrollments` n'ayant pas de `school_id`.
      verifyNever(
        () => duplicateDao.currentYearIdentities(
          academicYearId: any(named: 'academicYearId'),
          excludedStudentId: any(named: 'excludedStudentId'),
          excludedEnrollmentId: any(named: 'excludedEnrollmentId'),
        ),
      );
      verify(
        () => duplicateDao.previousYearCohortIdentities(
          excludedStudentId: 'self',
        ),
      ).called(1);
    },
  );

  test('une lecture qui lève devient un Left, jamais un corpus vide', () async {
    when(
      () => duplicateDao.previousYearCohortIdentities(
        excludedStudentId: any(named: 'excludedStudentId'),
      ),
    ).thenThrow(Exception('base fermée'));

    final result = await repository.loadDuplicateProbeCorpus(
      studentId: 'self',
      enrollmentId: 'self-e',
      academicYearId: 'ay-2026',
    );

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<StorageFailure>()), (_) {});
  });
}
