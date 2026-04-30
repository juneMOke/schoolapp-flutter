import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

class AttendanceRecord extends Equatable {
  final String? id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final StudentGender studentGender;
  final String classroomId;
  final String academicYearId;
  final DateTime attendanceDate;
  final bool present;
  final AbsenceReason? absenceReason;
  final String? absenceReasonNote;

  const AttendanceRecord({
    this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.classroomId,
    required this.academicYearId,
    required this.attendanceDate,
    required this.present,
    this.absenceReason,
    this.absenceReasonNote,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    classroomId,
    academicYearId,
    attendanceDate,
    present,
    absenceReason,
    absenceReasonNote,
  ];
}
