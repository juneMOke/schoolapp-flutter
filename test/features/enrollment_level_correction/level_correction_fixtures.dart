import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';

const String kSchool = 'school-1';
const String kYear = 'year-1';
const String kAuthor = 'u-1';
const String kEnrollment = 'enr-1';
const String kStudent = 'stu-1';

LevelCorrectionGesture correctionGesture(
  String id, {
  String enrollmentId = kEnrollment,
  String authorId = kAuthor,
}) => LevelCorrectionGesture(
  id: id,
  enrollmentId: enrollmentId,
  studentId: kStudent,
  academicYearId: kYear,
  fromSchoolLevelId: 'lvl-m2',
  toSchoolLevelId: 'lvl-p2',
  toSchoolLevelGroupId: 'grp-primaire',
  toClassroomId: 'cls-p2a',
  reason: 'Erreur de saisie au guichet',
  correctedAt: '2026-11-06T10:15:00.000Z',
  authorId: authorId,
);

/// Une inscription locale au niveau [schoolLevelId].
Future<void> insertEnrollment(
  DatabaseExecutor db, {
  String id = kEnrollment,
  String studentId = kStudent,
  String academicYearId = kYear,
  String schoolLevelId = 'lvl-m2',
}) => db.insert('enrollments', {
  'id': id,
  'student_id': studentId,
  'enrollment_type': 'NEW',
  'status': 'COMPLETED',
  'academic_year_id': academicYearId,
  'enrollment_date': '2026-09-01',
  'school_level_id': schoolLevelId,
  'sync_status': 'SYNCED',
});

/// Un versement de l'élève sur l'année, en vigueur sauf [cancelledAt].
Future<void> insertPayment(
  DatabaseExecutor db, {
  required String id,
  String studentId = kStudent,
  String academicYearId = kYear,
  int? cancelledAt,
}) => db.insert('payments', {
  'id': id,
  'client_uuid': id,
  'student_id': studentId,
  'academic_year_id': academicYearId,
  'paid_at': '2026-10-01T09:00:00.000Z',
  'cancelled_at': cancelledAt,
});
