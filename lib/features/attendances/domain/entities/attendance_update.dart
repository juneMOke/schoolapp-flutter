import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

class AttendanceUpdate extends Equatable {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final StudentGender studentGender;
  final bool present;
  final AbsenceReason? absenceReason;
  final String? absenceReasonNote;

  const AttendanceUpdate({
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.present,
    this.absenceReason,
    this.absenceReasonNote,
  });

  @override
  List<Object?> get props => [
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    present,
    absenceReason,
    absenceReasonNote,
  ];
}
