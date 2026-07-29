import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_offline_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

class MockEnrollmentReadDao extends Mock implements EnrollmentReadDao {}

class MockEnrollmentDraftDao extends Mock implements EnrollmentDraftDao {}

class MockEnrollmentSeedDao extends Mock implements EnrollmentSeedDao {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late MockEnrollmentReadDao readDao;
  late MockEnrollmentDraftDao draftDao;
  late MockEnrollmentSeedDao seedDao;
  late MockIdGenerator idGen;
  late MockSyncEngine syncEngine;
  late EnrollmentOfflineRepositoryImpl repo;
  const clock = 5000;

  setUpAll(() {
    registerFallbackValue(
      const StudentLocalModel(
        id: 'x',
        firstName: 'x',
        lastName: 'x',
        gender: 'MALE',
        dateOfBirth: '2000-01-01',
      ),
    );
    registerFallbackValue(
      const EnrollmentLocalModel(
        id: 'x',
        studentId: 'x',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'x',
        enrollmentDate: '2000-01-01',
      ),
    );
    registerFallbackValue(
      const GeneratedDocumentLocalModel(
        id: 'x',
        docDomain: 'ENROLLMENT',
        docType: 'AI',
        number: 'x',
      ),
    );
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(<ParentDraft>[]);
  });

  setUp(() {
    readDao = MockEnrollmentReadDao();
    draftDao = MockEnrollmentDraftDao();
    seedDao = MockEnrollmentSeedDao();
    idGen = MockIdGenerator();
    syncEngine = MockSyncEngine();
    repo = EnrollmentOfflineRepositoryImpl(
      readDao: readDao,
      draftDao: draftDao,
      seedDao: seedDao,
      idGenerator: idGen,
      syncEngine: syncEngine,
      now: () => clock,
    );
    // Défaut : aucun dossier existant → la garde anti double-réinscription du
    // seed RE laisse passer (les tests qui la testent surchargent ce stub).
    when(
      () => readDao.findLocalDossierRefForStudentYear(
        studentId: any(named: 'studentId'),
        academicYearId: any(named: 'academicYearId'),
      ),
    ).thenAnswer((_) async => null);
  });

  group('startDraft', () {
    test('NEW : génère enrollmentId puis studentId', () {
      final ids = <String>['enr-uuid', 'stu-uuid'];
      when(() => idGen.newId()).thenAnswer((_) => ids.removeAt(0));

      final result = repo.startDraft();

      expect(result.enrollmentId, 'enr-uuid');
      expect(result.studentId, 'stu-uuid');
      verify(() => idGen.newId()).called(2);
    });

    test(
      'RE/PRE : réutilise existingStudentId, ne génère que l\'inscription',
      () {
        when(() => idGen.newId()).thenReturn('enr-uuid');

        final result = repo.startDraft(existingStudentId: 'stu-existing');

        expect(result.enrollmentId, 'enr-uuid');
        expect(result.studentId, 'stu-existing');
        verify(() => idGen.newId()).called(1);
      },
    );
  });

  group('seedDraft', () {
    const reSeed = ConfirmEnrollmentDraft(
      studentId: 'stu-canonique',
      firstName: 'Amina',
      lastName: 'Moke',
      surname: 'Junior',
      gender: 'FEMALE',
      dateOfBirth: '2015-04-02',
      birthPlace: 'Kinshasa',
      matriculationNumber: 'KIN-2025-0001',
      enrollmentType: 'RE_ENROLLMENT',
      status: 'IN_PROGRESS',
      sourceRef: 'KIN-2025-0001',
      academicYearId: 'ay-2026',
      enrollmentDate: '2026-07-08',
      parents: [
        ConfirmParentDraft(
          firstName: 'Sarah',
          lastName: 'Moke',
          phoneNumber: '+243111',
          relationshipType: 'MOTHER',
        ),
      ],
    );

    test('RE : id inscription neuf, élève canonique conservé, matricule et '
        'sourceRef projetés sur les modèles', () async {
      final ids = <String>['enr-uuid', 'parent-uuid'];
      when(() => idGen.newId()).thenAnswer((_) => ids.removeAt(0));
      when(
        () => draftDao.seedDraft(
          student: any(named: 'student'),
          enrollment: any(named: 'enrollment'),
          parents: any(named: 'parents'),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenAnswer((_) async => true);

      final result = await repo.seedDraft(reSeed);

      final draftIds = result.getOrElse(() => throw StateError('left'));
      expect(draftIds.enrollmentId, 'enr-uuid');
      expect(draftIds.studentId, 'stu-canonique');
      final captured = verify(
        () => draftDao.seedDraft(
          student: captureAny(named: 'student'),
          enrollment: captureAny(named: 'enrollment'),
          parents: captureAny(named: 'parents'),
          nowMs: clock,
        ),
      ).captured;
      final student = captured[0] as StudentLocalModel;
      final enrollment = captured[1] as EnrollmentLocalModel;
      final parents = captured[2] as List<ParentDraft>;
      expect(student.id, 'stu-canonique');
      expect(student.matriculationNumber, 'KIN-2025-0001');
      expect(enrollment.id, 'enr-uuid');
      expect(enrollment.sourceRef, 'KIN-2025-0001');
      expect(enrollment.enrollmentType, 'RE_ENROLLMENT');
      expect(parents.single.parent.id, 'parent-uuid');
      expect(parents.single.relationshipType, 'MOTHER');
    });

    test('PRE/édition : conserve l\'enrollmentId serveur fourni', () async {
      when(
        () => draftDao.seedDraft(
          student: any(named: 'student'),
          enrollment: any(named: 'enrollment'),
          parents: any(named: 'parents'),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenAnswer((_) async => true);

      final result = await repo.seedDraft(
        const ConfirmEnrollmentDraft(
          studentId: 'stu-1',
          firstName: 'Beni',
          lastName: 'Kabila',
          gender: 'MALE',
          dateOfBirth: '2016-01-01',
          enrollmentType: 'PRE_ENROLLMENT',
          status: 'PRE_REGISTERED',
          sourceRef: 'pre-server-1',
          academicYearId: 'ay-2026',
          enrollmentDate: '2026-07-08',
        ),
        enrollmentId: 'e-server-1',
      );

      final draftIds = result.getOrElse(() => throw StateError('left'));
      expect(draftIds.enrollmentId, 'e-server-1');
      verifyNever(() => idGen.newId());
    });

    test('dossier local déjà confirmé → ValidationFailure', () async {
      when(() => idGen.newId()).thenReturn('x');
      when(
        () => draftDao.seedDraft(
          student: any(named: 'student'),
          enrollment: any(named: 'enrollment'),
          parents: any(named: 'parents'),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenAnswer((_) async => false);

      final result = await repo.seedDraft(reSeed);

      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('exception DAO → StorageFailure', () async {
      when(() => idGen.newId()).thenReturn('x');
      when(
        () => draftDao.seedDraft(
          student: any(named: 'student'),
          enrollment: any(named: 'enrollment'),
          parents: any(named: 'parents'),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenThrow(StateError('db down'));

      final result = await repo.seedDraft(reSeed);

      expect(result.fold((f) => f, (_) => null), isA<StorageFailure>());
    });

    test(
      'RE : élève déjà inscrit cette année → ValidationFailure sans doublon',
      () async {
        when(() => idGen.newId()).thenReturn('x');
        // Backstop dur : un dossier existe déjà pour (studentId, année cible).
        when(
          () => readDao.findLocalDossierRefForStudentYear(
            studentId: 'stu-canonique',
            academicYearId: 'ay-2026',
          ),
        ).thenAnswer(
          (_) async => const LocalDossierRef(
            enrollmentId: 'dossier-existant',
            syncState: SyncState.pendingSync,
          ),
        );

        final result = await repo.seedDraft(reSeed);

        expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
        // Aucun brouillon créé → pas de double-réinscription.
        verifyNever(
          () => draftDao.seedDraft(
            student: any(named: 'student'),
            enrollment: any(named: 'enrollment'),
            parents: any(named: 'parents'),
            nowMs: any(named: 'nowMs'),
          ),
        );
      },
    );

    test(
      'PRE (enrollmentId fourni) : la garde anti-doublon ne s\'applique PAS',
      () async {
        // enrollmentId fourni → resume/PRE, pas un seed frais → jamais bloqué même
        // si un dossier existe (idempotence sur l'id serveur).
        when(
          () => draftDao.seedDraft(
            student: any(named: 'student'),
            enrollment: any(named: 'enrollment'),
            parents: any(named: 'parents'),
            nowMs: any(named: 'nowMs'),
          ),
        ).thenAnswer((_) async => true);

        final result = await repo.seedDraft(
          const ConfirmEnrollmentDraft(
            studentId: 'stu-1',
            firstName: 'Beni',
            lastName: 'Kabila',
            gender: 'MALE',
            dateOfBirth: '2016-01-01',
            enrollmentType: 'PRE_ENROLLMENT',
            status: 'PRE_REGISTERED',
            academicYearId: 'ay-2026',
            enrollmentDate: '2026-07-08',
          ),
          enrollmentId: 'e-server-1',
        );

        expect(result.isRight(), isTrue);
        verifyNever(
          () => readDao.findLocalDossierRefForStudentYear(
            studentId: any(named: 'studentId'),
            academicYearId: any(named: 'academicYearId'),
          ),
        );
      },
    );
  });

  group('saveDraftIdentity', () {
    test('construit et insère les 2 lignes DRAFT (updatedAt = now)', () async {
      when(() => draftDao.insertDraftStudent(any())).thenAnswer((_) async {});
      when(
        () => draftDao.insertDraftEnrollment(any()),
      ).thenAnswer((_) async {});

      final result = await repo.saveDraftIdentity(
        enrollmentId: 'e1',
        studentId: 's1',
        firstName: 'Amina',
        lastName: 'Moke',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        matriculationNumber: 'MAT-9',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'ay-2026',
        schoolLevelId: 'lvl-1',
        enrollmentDate: '2026-07-06',
      );

      expect(result, const Right<Failure, Unit>(unit));
      final s =
          verify(
                () => draftDao.insertDraftStudent(captureAny()),
              ).captured.single
              as StudentLocalModel;
      expect(s.id, 's1');
      expect(s.firstName, 'Amina');
      expect(s.matriculationNumber, 'MAT-9');
      expect(s.updatedAt, clock);
      final e =
          verify(
                () => draftDao.insertDraftEnrollment(captureAny()),
              ).captured.single
              as EnrollmentLocalModel;
      expect(e.id, 'e1');
      expect(e.studentId, 's1');
      expect(e.schoolLevelId, 'lvl-1');
      expect(e.updatedAt, clock);
      expect(e.enrollmentType, 'NEW_ENROLLMENT');
      expect(e.status, 'IN_PROGRESS');
    });

    test('transmet enrollmentType/status tels quels (ex. reprise RE) — ne les '
        'requalifie jamais en dur', () async {
      when(() => draftDao.insertDraftStudent(any())).thenAnswer((_) async {});
      when(
        () => draftDao.insertDraftEnrollment(any()),
      ).thenAnswer((_) async {});

      await repo.saveDraftIdentity(
        enrollmentId: 'e-re',
        studentId: 's-re',
        firstName: 'Amina',
        lastName: 'Moke',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        enrollmentType: 'RE_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'ay-2026',
        enrollmentDate: '2026-07-06',
      );

      final e =
          verify(
                () => draftDao.insertDraftEnrollment(captureAny()),
              ).captured.single
              as EnrollmentLocalModel;
      expect(e.enrollmentType, 'RE_ENROLLMENT');
      expect(e.status, 'IN_PROGRESS');
    });

    test('exception DAO → Left(StorageFailure)', () async {
      when(
        () => draftDao.insertDraftStudent(any()),
      ).thenThrow(Exception('boom'));

      final result = await repo.saveDraftIdentity(
        enrollmentId: 'e1',
        studentId: 's1',
        firstName: 'Amina',
        lastName: 'Moke',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'ay-2026',
        enrollmentDate: '2026-07-06',
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<StorageFailure>()), (_) => fail('left'));
    });
  });

  group('saveDraftAddress', () {
    test('ne mappe que les colonnes non-null (snake_case)', () async {
      when(
        () => draftDao.updateDraftStudentColumns(
          any(),
          any(),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenAnswer((_) async {});

      final result = await repo.saveDraftAddress(
        studentId: 's1',
        city: 'Goma',
        phoneNumber: '+243900',
      );

      expect(result, const Right<Failure, Unit>(unit));
      final columns =
          verify(
                () => draftDao.updateDraftStudentColumns(
                  's1',
                  captureAny(),
                  nowMs: clock,
                ),
              ).captured.single
              as Map<String, Object?>;
      expect(columns, {'city': 'Goma', 'phone_number': '+243900'});
    });
  });

  group('saveDraftPreviousAcademic', () {
    test('mappe previous_* et convertit le bool en 0/1', () async {
      when(
        () => draftDao.updateDraftEnrollmentColumns(
          any(),
          any(),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenAnswer((_) async {});

      await repo.saveDraftPreviousAcademic(
        enrollmentId: 'e1',
        previousSchoolName: 'Sainte-Marie',
        previousRank: 3,
        validatedPreviousYear: true,
        transferReason: 'Déménagement',
      );

      final columns =
          verify(
                () => draftDao.updateDraftEnrollmentColumns(
                  'e1',
                  captureAny(),
                  nowMs: clock,
                ),
              ).captured.single
              as Map<String, Object?>;
      expect(columns['previous_school_name'], 'Sainte-Marie');
      expect(columns['previous_rank'], 3);
      expect(columns['validated_previous_year'], 1);
      expect(columns['transfer_reason'], 'Déménagement');
      expect(columns.containsKey('previous_rate'), isFalse);
    });
  });

  group('saveDraftTargetAcademic', () {
    test('mappe school_level_id / school_level_group_id non-null', () async {
      when(
        () => draftDao.updateDraftEnrollmentColumns(
          any(),
          any(),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenAnswer((_) async {});

      await repo.saveDraftTargetAcademic(
        enrollmentId: 'e1',
        schoolLevelId: 'l',
      );

      final columns =
          verify(
                () => draftDao.updateDraftEnrollmentColumns(
                  'e1',
                  captureAny(),
                  nowMs: clock,
                ),
              ).captured.single
              as Map<String, Object?>;
      expect(columns, {'school_level_id': 'l'});
    });
  });

  group('saveDraftGuardians', () {
    test(
      'mappe ConfirmParentDraft → ParentDraft (id généré + relation)',
      () async {
        when(() => idGen.newId()).thenReturn('p-uuid');
        when(
          () => draftDao.replaceDraftParents(
            any(),
            any(),
            nowMs: any(named: 'nowMs'),
          ),
        ).thenAnswer((_) async {});

        await repo.saveDraftGuardians(
          studentId: 's1',
          parents: const [
            ConfirmParentDraft(
              firstName: 'Sarah',
              lastName: 'Moke',
              phoneNumber: '+243111',
              relationshipType: 'MOTHER',
            ),
          ],
        );

        final drafts =
            verify(
                  () => draftDao.replaceDraftParents(
                    's1',
                    captureAny(),
                    nowMs: clock,
                  ),
                ).captured.single
                as List<ParentDraft>;
        expect(drafts, hasLength(1));
        expect(drafts.first.parent.id, 'p-uuid');
        expect(drafts.first.parent.firstName, 'Sarah');
        expect(drafts.first.relationshipType, 'MOTHER');
      },
    );
  });

  group('getDraftDetail', () {
    test('DAO null → Left(NotFoundFailure)', () async {
      when(() => readDao.getDetail('ghost')).thenAnswer((_) async => null);

      final result = await repo.getDraftDetail('ghost');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('left'),
      );
    });
  });

  group('finalizeDraft', () {
    test('construit le doc provisoire, délègue, flush opportuniste', () async {
      when(() => idGen.newId()).thenReturn('doc-uuid');
      when(
        () => draftDao.finalizeDraft(
          any(),
          document: any(named: 'document'),
          emitDocument: any(named: 'emitDocument'),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => syncEngine.flush(),
      ).thenAnswer((_) async => const SyncFlushReport());

      final result = await repo.finalizeDraft(enrollmentId: 'enrollment-1');

      expect(result, const Right<Failure, Unit>(unit));
      final doc =
          verify(
                () => draftDao.finalizeDraft(
                  'enrollment-1',
                  document: captureAny(named: 'document'),
                  emitDocument: true,
                  nowMs: clock,
                ),
              ).captured.single
              as GeneratedDocumentLocalModel;
      expect(doc.docDomain, 'ENROLLMENT');
      expect(doc.docType, 'AI');
      expect(doc.enrollmentId, 'enrollment-1');
      expect(doc.number, 'PROV-ENROLLME');
      verify(() => syncEngine.flush()).called(1);
    });

    test(
      'emitDocument=false → document null, pas de génération d\'id',
      () async {
        when(
          () => draftDao.finalizeDraft(
            any(),
            document: any(named: 'document'),
            emitDocument: any(named: 'emitDocument'),
            nowMs: any(named: 'nowMs'),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => syncEngine.flush(),
        ).thenAnswer((_) async => const SyncFlushReport());

        await repo.finalizeDraft(
          enrollmentId: 'enrollment-1',
          emitDocument: false,
        );

        verify(
          () => draftDao.finalizeDraft(
            'enrollment-1',
            document: null,
            emitDocument: false,
            nowMs: clock,
          ),
        ).called(1);
        verifyNever(() => idGen.newId());
      },
    );

    test('DAO renvoie false → Left(NotFoundFailure), pas de flush', () async {
      when(() => idGen.newId()).thenReturn('doc-uuid');
      when(
        () => draftDao.finalizeDraft(
          any(),
          document: any(named: 'document'),
          emitDocument: any(named: 'emitDocument'),
          nowMs: any(named: 'nowMs'),
        ),
      ).thenAnswer((_) async => false);

      final result = await repo.finalizeDraft(enrollmentId: 'enrollment-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('left'),
      );
      verifyNever(() => syncEngine.flush());
    });
  });

  group('seed depuis le local (lectures ref)', () {
    test('getReenrollmentCandidate présent → Right(candidat)', () async {
      const candidate = ReenrollmentCandidate(
        studentId: 's1',
        matriculationNumber: 'KIN-2025-0001',
        firstName: 'Amina',
        lastName: 'Moke',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
      );
      when(
        () => seedDao.findReenrollmentCandidateByStudentId('s1'),
      ).thenAnswer((_) async => candidate);

      final result = await repo.getReenrollmentCandidate('s1');

      expect(result, const Right<Failure, ReenrollmentCandidate>(candidate));
    });

    test(
      'getReenrollmentCandidate absent (cohorte vide) → Left(NotFoundFailure)',
      () async {
        when(
          () => seedDao.findReenrollmentCandidateByStudentId(any()),
        ).thenAnswer((_) async => null);

        final result = await repo.getReenrollmentCandidate('s1');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<NotFoundFailure>()),
          (_) => fail('attendu NotFoundFailure'),
        );
      },
    );

    test('getPreEnrollment présent → Right(préinscription)', () async {
      const pre = PreEnrollmentCandidate(
        id: 'pre-1',
        firstName: 'Amina',
        lastName: 'Moke',
      );
      when(
        () => seedDao.findPreEnrollmentById('pre-1'),
      ).thenAnswer((_) async => pre);

      final result = await repo.getPreEnrollment('pre-1');

      expect(result, const Right<Failure, PreEnrollmentCandidate>(pre));
    });

    test(
      'getPreEnrollment absent (snapshot vide) → Left(NotFoundFailure)',
      () async {
        when(
          () => seedDao.findPreEnrollmentById(any()),
        ).thenAnswer((_) async => null);

        final result = await repo.getPreEnrollment('pre-1');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<NotFoundFailure>()),
          (_) => fail('attendu NotFoundFailure'),
        );
      },
    );
  });

  group('searchReenrollmentCohort', () {
    const cand = ReenrollmentCandidate(
      studentId: 'stu-A',
      matriculationNumber: 'MAT-A',
      firstName: 'Awa',
      lastName: 'Ndiaye',
      gender: 'FEMALE',
      dateOfBirth: '2012-05-01',
    );

    test(
      'année courante résolue → superpose les dossiers de CETTE année',
      () async {
        when(
          () => seedDao.searchReenrollmentCandidates(
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((_) async => [cand]);
        when(
          () => seedDao.findCurrentAcademicYearId(),
        ).thenAnswer((_) async => 'ay-cur');
        when(
          () => readDao.getEnrollments(
            status: any(named: 'status'),
            academicYearId: any(named: 'academicYearId'),
          ),
        ).thenAnswer((_) async => const []);

        final result = await repo.searchReenrollmentCohort(
          schoolLevelId: 'lvl-2',
        );

        final r = result.getOrElse(() => throw StateError('left'));
        expect(r.candidates, [cand]);
        // Overlay scopé à l'année COURANTE (jamais les dossiers N-1 terminés, qui
        // masqueraient à tort le candidat à réinscrire).
        verify(
          () => readDao.getEnrollments(
            status: any(named: 'status'),
            academicYearId: 'ay-cur',
          ),
        ).called(1);
      },
    );

    test(
      'année courante non résolue → aucun overlay (getEnrollments non appelé)',
      () async {
        when(
          () => seedDao.searchReenrollmentCandidates(
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((_) async => [cand]);
        when(
          () => seedDao.findCurrentAcademicYearId(),
        ).thenAnswer((_) async => null);

        final result = await repo.searchReenrollmentCohort();

        final r = result.getOrElse(() => throw StateError('left'));
        expect(r.candidates, [cand]);
        expect(r.localDossiers, isEmpty);
        verifyNever(
          () => readDao.getEnrollments(
            status: any(named: 'status'),
            academicYearId: any(named: 'academicYearId'),
          ),
        );
      },
    );
  });
}
