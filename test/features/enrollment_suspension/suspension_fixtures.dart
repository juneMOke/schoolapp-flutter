import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_gesture.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:sqflite_common/sqlite_api.dart';

const String kSchool = 'school-1';
const String kYear = 'year-1';
const String kAuthor = 'u-1';

String enrollmentOf(String student) => 'enr-$student';

SuspensionGesture suspendGesture(
  String student, {
  String? id,
  String at = '2026-10-08T08:00:00.000Z',
  SuspensionReason? reason,
  String? precision,
}) => SuspensionGesture(
  op: SuspensionGestureOp.suspend,
  id: id ?? 'sus-$student',
  enrollmentId: enrollmentOf(student),
  studentId: student,
  academicYearId: kYear,
  at: at,
  authorId: kAuthor,
  reason: reason,
  precision: precision,
);

SuspensionGesture reactivateGesture(
  String student, {
  String? id,
  String at = '2026-10-09T08:00:00.000Z',
}) => SuspensionGesture(
  op: SuspensionGestureOp.reactivate,
  id: id ?? 'rea-$student',
  enrollmentId: enrollmentOf(student),
  studentId: student,
  academicYearId: kYear,
  at: at,
  authorId: kAuthor,
);

Future<void> insertMember(
  DatabaseExecutor db,
  String student, {
  String status = 'ACTIVE',
  String year = kYear,
  String classroomId = 'class-1',
  String? id,
}) => db.insert('ref_classroom_members', {
  'id': id ?? 'm-$student-$year',
  'student_id': student,
  'classroom_id': classroomId,
  'academic_year_id': year,
  'student_first_name': 'Prénom $student',
  'student_last_name': 'Nom $student',
  'status': status,
});

Future<String?> memberStatus(
  DatabaseExecutor db,
  String student, {
  String year = kYear,
}) async {
  final rows = await db.query(
    'ref_classroom_members',
    columns: ['status'],
    where: 'student_id = ? AND academic_year_id = ?',
    whereArgs: [student, year],
  );
  return rows.isEmpty ? null : rows.single['status'] as String?;
}
