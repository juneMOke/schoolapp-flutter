import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/update_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetAttendanceUseCase _getAttendanceUseCase;
  final UpdateAttendanceUseCase _updateAttendanceUseCase;

  AttendanceBloc({
    required GetAttendanceUseCase getAttendanceUseCase,
    required UpdateAttendanceUseCase updateAttendanceUseCase,
  })  : _getAttendanceUseCase = getAttendanceUseCase,
        _updateAttendanceUseCase = updateAttendanceUseCase,
        super(const AttendanceState()) {
    on<AttendanceFetchRequested>(_onFetchRequested);
    on<AttendanceRecordRequested>(_onRecordRequested);
    on<AttendanceResetRequested>(_onResetRequested);
  }

  Future<void> _onFetchRequested(
    AttendanceFetchRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(
      fetchStatus: AttendanceStatus.loading,
      fetchErrorType: AttendanceErrorType.none,
    ));

    final result = await _getAttendanceUseCase(
      classroomId: event.classroomId,
      date: event.date,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        fetchStatus: AttendanceStatus.failure,
        fetchErrorType: _mapFailureToErrorType(failure),
      )),
      (records) => emit(state.copyWith(
        fetchStatus: AttendanceStatus.success,
        records: records,
        fetchErrorType: AttendanceErrorType.none,
      )),
    );
  }

  Future<void> _onRecordRequested(
    AttendanceRecordRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(
      recordStatus: AttendanceStatus.loading,
      recordErrorType: AttendanceErrorType.none,
    ));

    final result = await _updateAttendanceUseCase(
      classroomId: event.classroomId,
      date: event.date,
      academicYearId: event.academicYearId,
      updates: event.updates,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        recordStatus: AttendanceStatus.failure,
        recordErrorType: _mapFailureToErrorType(failure),
      )),
      (_) => emit(state.copyWith(
        recordStatus: AttendanceStatus.success,
        recordErrorType: AttendanceErrorType.none,
      )),
    );
  }

  void _onResetRequested(
    AttendanceResetRequested event,
    Emitter<AttendanceState> emit,
  ) {
    emit(const AttendanceState());
  }

  AttendanceErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => AttendanceErrorType.network,
        NotFoundFailure() => AttendanceErrorType.notFound,
        ValidationFailure() => AttendanceErrorType.validation,
        UnauthorizedFailure() => AttendanceErrorType.unauthorized,
        InvalidCredentialsFailure() => AttendanceErrorType.invalidCredentials,
        ServerFailure() => AttendanceErrorType.server,
        StorageFailure() => AttendanceErrorType.storage,
        AuthFailure() => AttendanceErrorType.auth,
        _ => AttendanceErrorType.unknown,
      };
}
