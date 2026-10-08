import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../suspension_fixtures.dart';

void main() {
  late Database db;
  late EnrollmentSuspensionReadDao reader;

  setUp(() async {
    db = await openFullOfflineDb();
    reader = EnrollmentSuspensionReadDao(db);
  });
  tearDown(() => db.close());

  test('les désactivés avec une classe, et leur classe d\'origine', () async {
    await insertMember(db, 's1');
    await EnrollmentSuspensionWriteDao(db).suspend(
      [suspendGesture('s1'), suspendGesture('sans-classe')],
      schoolId: kSchool,
      nowMs: 1,
    );

    final members = await reader.suspendedMembers(
      schoolId: kSchool,
      academicYearId: kYear,
    );

    expect(members.single.classroomId, 'class-1');
    expect(members.single.lastName, 'Nom s1');
    expect(members.single.suspension.enrollmentId, enrollmentOf('s1'));
  });

  test('l\'inscription complétée d\'un élève sur l\'année', () async {
    Future<void> enrollment(String id, String status) =>
        db.insert('enrollments', {
          'id': id,
          'student_id': 's1',
          'academic_year_id': kYear,
          'enrollment_type': 'NEW_ENROLLMENT',
          'status': status,
          'enrollment_date': '2026-09-01',
          'sync_status': 'SYNCED',
          'updated_at': 1,
        });
    await enrollment('e-draft', 'IN_PROGRESS');
    expect(
      await reader.completedEnrollmentOf(
        studentId: 's1',
        academicYearId: kYear,
      ),
      isNull,
    );
    await enrollment('e-done', 'COMPLETED');
    expect(
      await reader.completedEnrollmentOf(
        studentId: 's1',
        academicYearId: kYear,
      ),
      'e-done',
    );
  });
}
