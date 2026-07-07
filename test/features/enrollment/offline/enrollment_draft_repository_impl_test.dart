import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_offline_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

class MockEnrollmentLocalDao extends Mock implements EnrollmentLocalDao {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late MockEnrollmentLocalDao dao;
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
    dao = MockEnrollmentLocalDao();
    idGen = MockIdGenerator();
    syncEngine = MockSyncEngine();
    repo = EnrollmentOfflineRepositoryImpl(
      dao: dao,
      idGenerator: idGen,
      syncEngine: syncEngine,
      now: () => clock,
    );
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

  group('saveDraftIdentity', () {
    test('construit et insère les 2 lignes DRAFT (updatedAt = now)', () async {
      when(() => dao.insertDraftStudent(any())).thenAnswer((_) async {});
      when(() => dao.insertDraftEnrollment(any())).thenAnswer((_) async {});

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
          verify(() => dao.insertDraftStudent(captureAny())).captured.single
              as StudentLocalModel;
      expect(s.id, 's1');
      expect(s.firstName, 'Amina');
      expect(s.matriculationNumber, 'MAT-9');
      expect(s.updatedAt, clock);
      final e =
          verify(() => dao.insertDraftEnrollment(captureAny())).captured.single
              as EnrollmentLocalModel;
      expect(e.id, 'e1');
      expect(e.studentId, 's1');
      expect(e.schoolLevelId, 'lvl-1');
      expect(e.updatedAt, clock);
    });

    test('exception DAO → Left(StorageFailure)', () async {
      when(() => dao.insertDraftStudent(any())).thenThrow(Exception('boom'));

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
        () => dao.updateDraftStudentColumns(
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
                () => dao.updateDraftStudentColumns(
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
        () => dao.updateDraftEnrollmentColumns(
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
                () => dao.updateDraftEnrollmentColumns(
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
        () => dao.updateDraftEnrollmentColumns(
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
                () => dao.updateDraftEnrollmentColumns(
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
          () =>
              dao.replaceDraftParents(any(), any(), nowMs: any(named: 'nowMs')),
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
                  () =>
                      dao.replaceDraftParents('s1', captureAny(), nowMs: clock),
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
      when(() => dao.getDetail('ghost')).thenAnswer((_) async => null);

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
        () => dao.finalizeDraft(
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
                () => dao.finalizeDraft(
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
          () => dao.finalizeDraft(
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
          () => dao.finalizeDraft(
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
        () => dao.finalizeDraft(
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
}
