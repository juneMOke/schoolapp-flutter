import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_student_attendance_summary_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_failure_mapper.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/student_attendance_summary_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/student_attendance_summary_state.dart';

class StudentAttendanceSummaryBloc
    extends Bloc<StudentAttendanceSummaryEvent, StudentAttendanceSummaryState> {
  final GetStudentAttendanceSummaryUseCase _getStudentAttendanceSummaryUseCase;

  StudentAttendanceSummaryBloc({
    required GetStudentAttendanceSummaryUseCase
    getStudentAttendanceSummaryUseCase,
  }) : _getStudentAttendanceSummaryUseCase = getStudentAttendanceSummaryUseCase,
       super(const StudentAttendanceSummaryState()) {
    on<StudentAttendanceSummaryRequested>(_onRequested);
  }

  Future<void> _onRequested(
    StudentAttendanceSummaryRequested event,
    Emitter<StudentAttendanceSummaryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StudentAttendanceSummaryStatus.loading,
        errorType: AttendanceErrorType.none,
      ),
    );

    final result = await _getStudentAttendanceSummaryUseCase(
      studentId: event.studentId,
      period: event.period,
      month: event.month,
      week: event.week,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StudentAttendanceSummaryStatus.failure,
          errorType: mapFailureToAttendanceErrorType(failure),
        ),
      ),
      (summary) => emit(
        state.copyWith(
          status: StudentAttendanceSummaryStatus.success,
          summary: summary,
          errorType: AttendanceErrorType.none,
        ),
      ),
    );
  }
}
