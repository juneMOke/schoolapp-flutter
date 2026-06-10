import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';

sealed class AttendanceEvent extends Equatable {
  const AttendanceEvent();
}

class AttendanceFetchRequested extends AttendanceEvent {
  final String classroomId;
  final DateTime date;
  final String academicYearId;

  const AttendanceFetchRequested({
    required this.classroomId,
    required this.date,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [classroomId, date, academicYearId];
}

class AttendancePresenceToggled extends AttendanceEvent {
  final String studentId;
  final bool present;

  const AttendancePresenceToggled({
    required this.studentId,
    required this.present,
  });

  @override
  List<Object?> get props => [studentId, present];
}

class AttendanceAbsenceReasonChanged extends AttendanceEvent {
  final String studentId;
  final AbsenceReason? absenceReason;

  const AttendanceAbsenceReasonChanged({
    required this.studentId,
    required this.absenceReason,
  });

  @override
  List<Object?> get props => [studentId, absenceReason];
}

class AttendanceAbsenceNoteChanged extends AttendanceEvent {
  final String studentId;
  final String note;

  const AttendanceAbsenceNoteChanged({
    required this.studentId,
    required this.note,
  });

  @override
  List<Object?> get props => [studentId, note];
}

class AttendanceSaveRequested extends AttendanceEvent {
  const AttendanceSaveRequested();

  @override
  List<Object?> get props => [];
}

class AttendanceSaveStatusResetRequested extends AttendanceEvent {
  const AttendanceSaveStatusResetRequested();

  @override
  List<Object?> get props => [];
}

class AttendanceResetRequested extends AttendanceEvent {
  const AttendanceResetRequested();

  @override
  List<Object?> get props => [];
}

class AttendanceMarkAllPresentRequested extends AttendanceEvent {
  const AttendanceMarkAllPresentRequested();

  @override
  List<Object?> get props => [];
}
