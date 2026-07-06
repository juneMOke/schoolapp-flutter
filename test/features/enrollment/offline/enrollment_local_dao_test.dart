import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

import '../../offline_full_db.dart';

void main() {
  late Database db;
  late EnrollmentLocalDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = EnrollmentLocalDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  StudentLocalModel student({String id = 's1', String phone = '+243900'}) =>
      StudentLocalModel(
        id: id,
        firstName: 'Amina',
        lastName: 'Moke',
        surname: 'Junior',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        birthPlace: 'Kinshasa',
        nationality: 'CD',
        phoneNumber: phone,
        updatedAt: 100,
      );

  EnrollmentLocalModel enrollment({
    String id = 'e1',
    String studentId = 's1',
  }) => EnrollmentLocalModel(
    id: id,
    studentId: studentId,
    enrollmentType: 'NEW_ENROLLMENT',
    status: 'IN_PROGRESS',
    academicYearId: 'ay-2026',
    schoolLevelId: 'lvl-1',
    enrollmentDate: '2026-07-06',
    updatedAt: 100,
  );

  ParentDraft parent({
    String id = 'p1',
    String phone = '+243111',
    String rel = 'MOTHER',
  }) => ParentDraft(
    parent: ParentLocalModel(
      id: id,
      firstName: 'Sarah',
      lastName: 'Moke',
      phoneNumber: phone,
      updatedAt: 100,
    ),
    relationshipType: rel,
  );

  GeneratedDocumentLocalModel doc({String enrollmentId = 'e1'}) =>
      GeneratedDocumentLocalModel(
        id: 'd1',
        docDomain: 'ENROLLMENT',
        enrollmentId: enrollmentId,
        studentId: 's1',
        docType: 'AI',
        number: 'PROV-ABCDEF12',
        createdAt: 100,
      );

  group('confirmEnrollment (F3)', () {
    test('écrit student(PENDING, matricule NULL), enrollment, parent, doc, '
        'outbox en une transaction', () async {
      await dao.confirmEnrollment(
        student: student(),
        enrollment: enrollment(),
        parents: [parent()],
        document: doc(),
        outboxEntryId: 'ob1',
        schoolId: 'school-1',
        nowMs: 1000,
      );

      final sRows = await db.query('students');
      expect(sRows, hasLength(1));
      expect(sRows.first['sync_status'], SyncState.pendingSync.dbValue);
      expect(sRows.first['matriculation_number'], isNull);

      final eRows = await db.query('enrollments');
      expect(eRows.first['sync_status'], SyncState.pendingSync.dbValue);

      final link = await db.query('student_parent');
      expect(link, hasLength(1));
      expect(link.first['relationship_type'], 'MOTHER');

      final docRows = await db.query('generated_documents');
      expect(docRows.first['status'], 'PROVISIONAL');
      expect((docRows.first['number'] as String).startsWith('PROV-'), isTrue);

      final ob = await db.query('outbox');
      expect(ob, hasLength(1));
      expect(ob.first['aggregate_type'], 'ENROLLMENT');
      expect(ob.first['aggregate_id'], 'e1');
      expect(ob.first['school_id'], 'school-1');
      final payload =
          jsonDecode(ob.first['payload'] as String) as Map<String, dynamic>;
      expect(payload['enrollment']['id'], 'e1');
      expect(payload['parents'], hasLength(1));
    });

    test(
      'dédup parent par téléphone (fratrie) : réutilise l\'id existant',
      () async {
        // Premier dossier avec le parent p1.
        await dao.confirmEnrollment(
          student: student(id: 's1', phone: '+243900'),
          enrollment: enrollment(id: 'e1', studentId: 's1'),
          parents: [parent(id: 'p1', phone: '+243111')],
          outboxEntryId: 'ob1',
          nowMs: 1000,
        );
        // Second dossier (fratrie), même téléphone mais id provisoire différent.
        await dao.confirmEnrollment(
          student: student(id: 's2', phone: '+243901'),
          enrollment: enrollment(id: 'e2', studentId: 's2'),
          parents: [parent(id: 'p2', phone: '+243111')],
          outboxEntryId: 'ob2',
          nowMs: 2000,
        );

        final parents = await db.query('parents');
        expect(parents, hasLength(1), reason: 'un seul parent dédupliqué');
        expect(parents.first['id'], 'p1');

        final links = await db.query('student_parent');
        expect(links, hasLength(2));
        expect(
          links.every((l) => l['parent_id'] == 'p1'),
          isTrue,
          reason: 'les deux liens pointent le parent dédupliqué',
        );
      },
    );
  });

  group('applyEnrollmentAck (F4 remap)', () {
    test('COMMITTED : matricule/email, parent provisoire→canonique (parents ET '
        'student_parent), doc DEFINITIVE, SYNCED', () async {
      await dao.confirmEnrollment(
        student: student(),
        enrollment: enrollment(),
        parents: [parent(id: 'p-prov')],
        document: doc(),
        outboxEntryId: 'ob1',
        nowMs: 1000,
      );

      await dao.applyEnrollmentAck(
        const EnrollmentAck(
          clientEnrollmentId: 'e1',
          outcome: 'COMMITTED',
          enrollment: AckEnrollment(
            id: 'e1',
            status: 'ADMIN_COMPLETED',
            enrollmentCode: 'ETL-2026-001',
          ),
          student: AckStudent(
            id: 's1',
            matriculationNumber: 'MAT-0001',
            email: 'amina@school.cd',
          ),
          parents: [AckParent(clientId: 'p-prov', id: 'p-canon')],
          document: AckDocument(
            id: 'd1',
            type: 'AI',
            number: 'ETL-AI-0001',
            verificationToken: 'tok-123',
          ),
        ),
        nowMs: 5000,
      );

      final s = (await db.query('students')).first;
      expect(s['matriculation_number'], 'MAT-0001');
      expect(s['email'], 'amina@school.cd');
      expect(s['sync_status'], SyncState.synced.dbValue);

      final parents = await db.query('parents');
      expect(parents, hasLength(1));
      expect(parents.first['id'], 'p-canon');

      final link = (await db.query('student_parent')).first;
      expect(link['parent_id'], 'p-canon');

      final d = (await db.query('generated_documents')).first;
      expect(d['status'], 'DEFINITIVE');
      expect(d['number'], 'ETL-AI-0001');
      expect(d['verification_token'], 'tok-123');

      final e = (await db.query('enrollments')).first;
      expect(e['sync_status'], SyncState.synced.dbValue);
      expect(e['enrollment_code'], 'ETL-2026-001');
      expect(e['status'], 'ADMIN_COMPLETED');
    });

    test(
      'VALIDATION_ERROR : SYNC_ERROR + message sur enrollment et student',
      () async {
        await dao.confirmEnrollment(
          student: student(),
          enrollment: enrollment(),
          parents: [parent()],
          outboxEntryId: 'ob1',
          nowMs: 1000,
        );

        await dao.applyEnrollmentAck(
          const EnrollmentAck(
            clientEnrollmentId: 'e1',
            outcome: 'VALIDATION_ERROR',
            error: AckError(field: 'dateOfBirth', message: 'Date invalide'),
          ),
          nowMs: 5000,
        );

        final e = (await db.query('enrollments')).first;
        expect(e['sync_status'], SyncState.syncError.dbValue);
        expect(e['sync_error'], 'Date invalide');
        final s = (await db.query('students')).first;
        expect(s['sync_status'], SyncState.syncError.dbValue);
      },
    );
  });

  group('lectures', () {
    setUp(() async {
      await dao.confirmEnrollment(
        student: student(),
        enrollment: enrollment(),
        parents: [parent()],
        document: doc(),
        outboxEntryId: 'ob1',
        nowMs: 1000,
      );
    });

    test('getEnrollments + filtre par statut', () async {
      expect(await dao.getEnrollments(), hasLength(1));
      expect(await dao.getEnrollments(status: 'IN_PROGRESS'), hasLength(1));
      expect(await dao.getEnrollments(status: 'COMPLETED'), isEmpty);
    });

    test('searchByName / searchByDateOfBirth', () async {
      expect(await dao.searchByName('Moke'), hasLength(1));
      expect(await dao.searchByName('Zzz'), isEmpty);
      expect(await dao.searchByDateOfBirth('2015-04-02'), hasLength(1));
    });

    test('searchByAcademicInfo filtre sur l\'inscription', () async {
      expect(
        await dao.searchByAcademicInfo(academicYearId: 'ay-2026'),
        hasLength(1),
      );
      expect(await dao.searchByAcademicInfo(schoolLevelId: 'other'), isEmpty);
    });

    test('getDetail assemble élève + tuteurs + documents', () async {
      final detail = await dao.getDetail('e1');
      expect(detail, isNotNull);
      expect(detail!.student.firstName, 'Amina');
      expect(detail.parents, hasLength(1));
      expect(detail.documents, hasLength(1));
    });
  });

  group('isStudentEnrollmentSynced (FIFO gate)', () {
    test('faux tant que PENDING, vrai une fois SYNCED, vrai si aucune '
        'inscription locale', () async {
      await dao.confirmEnrollment(
        student: student(),
        enrollment: enrollment(),
        parents: [parent()],
        outboxEntryId: 'ob1',
        nowMs: 1000,
      );
      expect(await dao.isStudentEnrollmentSynced('s1'), isFalse);

      await dao.applyEnrollmentAck(
        const EnrollmentAck(
          clientEnrollmentId: 'e1',
          outcome: 'COMMITTED',
          student: AckStudent(id: 's1', matriculationNumber: 'MAT-1'),
        ),
        nowMs: 2000,
      );
      expect(await dao.isStudentEnrollmentSynced('s1'), isTrue);
      // Élève préexistant (aucune inscription locale).
      expect(await dao.isStudentEnrollmentSynced('unknown'), isTrue);
    });
  });
}
