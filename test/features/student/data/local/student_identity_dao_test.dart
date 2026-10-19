import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/student/data/local/student_identity_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../offline_full_db.dart';

void main() {
  late Database db;
  late StudentIdentityDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = StudentIdentityDao(db);
    await db.insert('students', {
      'id': 's1',
      'first_name': 'Grâce',
      'last_name': 'MBUYI',
      'surname': 'Kalala',
      'gender': 'female',
      'date_of_birth': '2012-03-04',
    });
    await db.insert('ref_school_level_groups', {
      'id': 'g1',
      'name': 'Primaire',
      'code': 'PRI',
      'academic_year_id': 'y1',
    });
    for (final level in [('l1', '5e A'), ('l2', '6e B')]) {
      await db.insert('ref_school_levels', {
        'id': level.$1,
        'name': level.$2,
        'code': level.$1,
        'level_group_id': 'g1',
      });
    }
  });

  tearDown(() => db.close());

  Future<void> enroll(
    String id, {
    required String levelId,
    String status = 'VALIDATED',
    String year = 'y1',
    int updatedAt = 1,
  }) => db.insert('enrollments', {
    'id': id,
    'student_id': 's1',
    'enrollment_type': 'NEW',
    'status': status,
    'academic_year_id': year,
    'school_level_id': levelId,
    'enrollment_date': '2025-09-01',
    'updated_at': updatedAt,
  });

  test('un élève inconnu rend null', () async {
    expect(await dao.find(studentId: 'absent', academicYearId: 'y1'), isNull);
  });

  test('l’identité et la classe de l’année, cycle par le niveau', () async {
    await enroll('e1', levelId: 'l1');
    final identity = (await dao.find(
      studentId: 's1',
      academicYearId: 'y1',
    ))!.toEntity();
    expect(identity.firstName, 'Grâce');
    expect(identity.lastName, 'MBUYI');
    expect(identity.surname, 'Kalala');
    expect(identity.gender, 'FEMALE');
    expect(identity.levelName, '5e A');
    expect(identity.levelGroupName, 'Primaire');
  });

  test('sans inscription cette année : le nom, sans classe', () async {
    await enroll('e1', levelId: 'l1', year: 'y0');
    final identity = (await dao.find(
      studentId: 's1',
      academicYearId: 'y1',
    ))!.toEntity();
    expect(identity.lastName, 'MBUYI');
    expect(identity.levelName, isEmpty);
  });

  test(
    'l’inscription annulée cède à celle qui vit, même plus récente',
    () async {
      await enroll('e1', levelId: 'l1', updatedAt: 1);
      await enroll('e2', levelId: 'l2', status: 'CANCELLED', updatedAt: 9);
      final identity = (await dao.find(
        studentId: 's1',
        academicYearId: 'y1',
      ))!.toEntity();
      expect(identity.levelName, '5e A');
    },
  );
}
