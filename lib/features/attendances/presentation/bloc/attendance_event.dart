import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';

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

class AttendanceRecordRequested extends AttendanceEvent {
  final String classroomId;
  final DateTime date;
  final String academicYearId;
  final List<AttendanceUpdate> updates;

  const AttendanceRecordRequested({
    required this.classroomId,
    required this.date,
    required this.academicYearId,
    required this.updates,
  });

  @override
  List<Object?> get props => [classroomId, date, academicYearId, updates];
}

class AttendanceResetRequested extends AttendanceEvent {
  const AttendanceResetRequested();

  @override
  List<Object?> get props => [];
}
