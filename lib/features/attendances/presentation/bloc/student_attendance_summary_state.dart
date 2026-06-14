import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';

enum StudentAttendanceSummaryStatus { initial, loading, success, failure }

class StudentAttendanceSummaryState extends Equatable {
  final StudentAttendanceSummaryStatus status;
  final StudentAttendanceSummary? summary;

  /// Reutilise le type d'erreur partage du module (meme pattern d'erreur).
  final AttendanceErrorType errorType;

  const StudentAttendanceSummaryState({
    this.status = StudentAttendanceSummaryStatus.initial,
    this.summary,
    this.errorType = AttendanceErrorType.none,
  });

  StudentAttendanceSummaryState copyWith({
    StudentAttendanceSummaryStatus? status,
    StudentAttendanceSummary? summary,
    AttendanceErrorType? errorType,
  }) => StudentAttendanceSummaryState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, summary, errorType];
}
