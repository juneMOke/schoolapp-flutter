import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_attendance_overview_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_failure_mapper.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';

class AttendanceOverviewBloc
    extends Bloc<AttendanceOverviewEvent, AttendanceOverviewState> {
  final GetAttendanceOverviewUseCase _getAttendanceOverviewUseCase;

  AttendanceOverviewBloc({
    required GetAttendanceOverviewUseCase getAttendanceOverviewUseCase,
  }) : _getAttendanceOverviewUseCase = getAttendanceOverviewUseCase,
       super(const AttendanceOverviewState()) {
    on<AttendanceOverviewRequested>(_onRequested);
    on<AttendanceOverviewRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onRequested(
    AttendanceOverviewRequested event,
    Emitter<AttendanceOverviewState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AttendanceOverviewStatus.loading,
        errorType: AttendanceErrorType.none,
        selectedPeriod: event.period,
        selectedMonth: event.month,
        selectedWeek: event.week,
      ),
    );

    final result = await _getAttendanceOverviewUseCase(
      period: event.period,
      month: event.month,
      week: event.week,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AttendanceOverviewStatus.failure,
          errorType: mapFailureToAttendanceErrorType(failure),
        ),
      ),
      (overview) => emit(
        state.copyWith(
          status: AttendanceOverviewStatus.success,
          overview: overview,
          errorType: AttendanceErrorType.none,
        ),
      ),
    );
  }

  /// Relance la requete avec la periode actuellement selectionnee.
  Future<void> _onRefreshRequested(
    AttendanceOverviewRefreshRequested event,
    Emitter<AttendanceOverviewState> emit,
  ) async {
    add(
      AttendanceOverviewRequested(
        period: state.selectedPeriod,
        month: state.selectedMonth,
        week: state.selectedWeek,
      ),
    );
  }
}
