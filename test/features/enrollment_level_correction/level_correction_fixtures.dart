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
