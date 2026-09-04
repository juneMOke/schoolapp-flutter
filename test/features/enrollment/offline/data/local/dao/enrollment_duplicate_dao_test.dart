import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_duplicate_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';

import '../../../../../offline_full_db.dart';

void main() {
  late Database db;
  late EnrollmentDuplicateDao dao;

  const year = 'ay-2026';
  const otherYear = 'ay-2025';

  setUp(() async {
    db = await openFullOfflineDb();
    dao = EnrollmentDuplicateDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertStudent({
    required String id,
    String firstName = 'Jean',
    String lastName = 'Mukendi',
    String? surname = 'Kabeya',
    String dateOfBirth = '2015-03-04',
  }) => db.insert('students', {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'surname': surname,
    'gender': 'MALE',
    'date_of_birth': dateOfBirth,
    'updated_at': 100,
  });

  Future<void> insertEnrollment({
    required String id,
    required String studentId,
    String academicYearId = year,
    String status = 'COMPLETED',
    String syncStatus = 'SYNCED',
  }) => db.insert('enrollments', {
    'id': id,
    'student_id': studentId,
    'enrollment_type': 'NEW_ENROLLMENT',
    'status': status,
    'academic_year_id': academicYearId,
    'enrollment_date': '2026-09-01',
    'sync_status': syncStatus,
    'updated_at': 100,
  });

  Future<void> insertCohort({
    required String studentId,
    String firstName = 'Jean',
    String lastName = 'Mukendi',
    String? surname = 'Kabeya',
    String dateOfBirth = '2015-03-04',
  }) => db.insert('ref_previous_year_students', {
    'student_id': studentId,
    'matriculation_number': 'MAT-$studentId',
    'first_name': firstName,
    'last_name': lastName,
    'surname': surname,
    'gender': 'MALE',
    'date_of_birth': dateOfBirth,
  });

  Future<List<String>> currentYearStudentIds({
    String excludedStudentId = 'self',
    String excludedEnrollmentId = 'self-e',
  }) async {
    final rows = await dao.currentYearIdentities(
      academicYearId: year,
      excludedStudentId: excludedStudentId,
      excludedEnrollmentId: excludedEnrollmentId,
    );
    return [for (final r in rows) r.studentId];
  }

  group('currentYearIdentities', () {
    test('remonte l\'identité et les deux ids du dossier', () async {
      await insertStudent(id: 's1');
      await insertEnrollment(id: 'e1', studentId: 's1');

      final rows = await dao.currentYearIdentities(
        academicYearId: year,
        excludedStudentId: 'self',
        excludedEnrollmentId: 'self-e',
      );

      expect(rows, hasLength(1));
      expect(rows.single.studentId, 's1');
      expect(rows.single.enrollmentId, 'e1');
      expect(rows.single.source, EnrollmentDuplicateSource.currentYearDossier);
      expect(rows.single.identity.lastName, 'Mukendi');
      expect(rows.single.identity.firstName, 'Jean');
      expect(rows.single.identity.surname, 'Kabeya');
      expect(rows.single.identity.dateOfBirth, '2015-03-04');
    });

    test('un dossier d\'une AUTRE année ne remonte pas', () async {
      await insertStudent(id: 's1');
      await insertEnrollment(
        id: 'e1',
        studentId: 's1',
        academicYearId: otherYear,
      );

      expect(await currentYearStudentIds(), isEmpty);
    });

    test('exclut le brouillon en cours par son studentId', () async {
      await insertStudent(id: 'self');
      await insertEnrollment(id: 'e-self', studentId: 'self');

      expect(
        await currentYearStudentIds(
          excludedStudentId: 'self',
          excludedEnrollmentId: 'autre',
        ),
        isEmpty,
      );
    });

    test('exclut aussi par enrollmentId — la seconde ceinture', () async {
      // Cas tordu mais réel : l'élève a été rattaché autrement, seul l'id du
      // dossier désigne encore le brouillon en cours.
      await insertStudent(id: 's1');
      await insertEnrollment(id: 'e-self', studentId: 's1');

      expect(
        await currentYearStudentIds(
          excludedStudentId: 'autre',
          excludedEnrollmentId: 'e-self',
        ),
        isEmpty,
      );
    });

    test('un brouillon DRAFT remonte — c\'est le doublon du matin', () async {
      await insertStudent(id: 's1');
      await insertEnrollment(
        id: 'e1',
        studentId: 's1',
        status: 'IN_PROGRESS',
        syncStatus: 'DRAFT',
      );

      expect(await currentYearStudentIds(), ['s1']);
    });

    test('un dossier CANCELLED remonte aussi — l\'enfant est là', () async {
      await insertStudent(id: 's1');
      await insertEnrollment(id: 'e1', studentId: 's1', status: 'CANCELLED');

      expect(await currentYearStudentIds(), ['s1']);
    });

    test('un élève sans dossier de l\'année ne remonte pas', () async {
      await insertStudent(id: 's1');

      expect(await currentYearStudentIds(), isEmpty);
    });

    test('un post-nom absent devient la chaîne vide', () async {
      await insertStudent(id: 's1', surname: null);
      await insertEnrollment(id: 'e1', studentId: 's1');

      final rows = await dao.currentYearIdentities(
        academicYearId: year,
        excludedStudentId: 'self',
        excludedEnrollmentId: 'self-e',
      );

      expect(rows.single.identity.surname, '');
    });

    test('ordre stable par nom puis prénom', () async {
      await insertStudent(id: 's1', lastName: 'Tshibangu', firstName: 'Ana');
      await insertStudent(id: 's2', lastName: 'Ilunga', firstName: 'Zoe');
      await insertStudent(id: 's3', lastName: 'Ilunga', firstName: 'Ana');
      await insertEnrollment(id: 'e1', studentId: 's1');
      await insertEnrollment(id: 'e2', studentId: 's2');
      await insertEnrollment(id: 'e3', studentId: 's3');

      expect(await currentYearStudentIds(), ['s3', 's2', 's1']);
    });
  });

  group('previousYearCohortIdentities', () {
    test('remonte l\'identité, sans dossier', () async {
      await insertCohort(studentId: 'c1');

      final rows = await dao.previousYearCohortIdentities(
        excludedStudentId: 'self',
      );

      expect(rows, hasLength(1));
      expect(rows.single.studentId, 'c1');
      expect(rows.single.enrollmentId, isNull);
      expect(rows.single.source, EnrollmentDuplicateSource.previousYearCohort);
      expect(rows.single.identity.dateOfBirth, '2015-03-04');
    });

    test('exclut le brouillon en cours par son studentId', () async {
      // Le cas arrive vraiment : un candidat N-1 dont la réinscription est en
      // cours porte le MÊME student_id canonique que le brouillon.
      await insertCohort(studentId: 'self');

      expect(
        await dao.previousYearCohortIdentities(excludedStudentId: 'self'),
        isEmpty,
      );
    });

    test('un post-nom absent devient la chaîne vide', () async {
      await insertCohort(studentId: 'c1', surname: null);

      final rows = await dao.previousYearCohortIdentities(
        excludedStudentId: 'self',
      );

      expect(rows.single.identity.surname, '');
    });

    test('cohorte vide — la lecture ne lève pas, elle se tait', () async {
      expect(
        await dao.previousYearCohortIdentities(excludedStudentId: 'self'),
        isEmpty,
      );
    });
  });
}
