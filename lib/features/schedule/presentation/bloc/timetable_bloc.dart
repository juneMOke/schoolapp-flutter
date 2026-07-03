import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_classroom_grid_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_my_timetable_usecase.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_event.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_state.dart';

/// BLoC de **lecture** de l'emploi du temps (cœur de l'app enseignant).
///
/// Ne déclenche rien au montage : attend un [TimetableRequested] (emploi du
/// temps de l'enseignant connecté) ou un [ClassroomGridRequested] (grille d'une
/// classe). Les cases `null` de la matrice sont des créneaux libres — jamais
/// traitées comme une erreur.
class TimetableBloc extends Bloc<TimetableEvent, TimetableState> {
  final GetMyTimetableUseCase _getMyTimetable;
  final GetClassroomGridUseCase _getClassroomGrid;

  TimetableBloc({
    required GetMyTimetableUseCase getMyTimetable,
    required GetClassroomGridUseCase getClassroomGrid,
  }) : _getMyTimetable = getMyTimetable,
       _getClassroomGrid = getClassroomGrid,
       super(const TimetableState()) {
    on<TimetableRequested>(_onTimetableRequested);
    on<ClassroomGridRequested>(_onClassroomGridRequested);
  }

  Future<void> _onTimetableRequested(
    TimetableRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TimetableStatus.loading,
        errorType: ScheduleErrorType.none,
      ),
    );

    final result = await _getMyTimetable(event.academicYearId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TimetableStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (timetable) => emit(
        state.copyWith(
          status: TimetableStatus.success,
          timetable: timetable,
          errorType: ScheduleErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onClassroomGridRequested(
    ClassroomGridRequested event,
    Emitter<TimetableState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TimetableStatus.loading,
        errorType: ScheduleErrorType.none,
      ),
    );

    final result = await _getClassroomGrid(
      GetClassroomGridParams(
        classroomId: event.classroomId,
        academicYearId: event.academicYearId,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: TimetableStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (timetable) => emit(
        state.copyWith(
          status: TimetableStatus.success,
          timetable: timetable,
          errorType: ScheduleErrorType.none,
        ),
      ),
    );
  }

  ScheduleErrorType _mapFailureToErrorType(
    Failure failure,
  ) => switch (failure) {
    NetworkFailure() => ScheduleErrorType.network,
    NotFoundFailure() => ScheduleErrorType.notFound,
    ValidationFailure() => ScheduleErrorType.validation,
    // Convention projet (cf. interceptor Dio) : HTTP 403 -> UnauthorizedFailure
    // -> forbidden ; HTTP 401 -> InvalidCredentialsFailure -> invalidCredentials.
    UnauthorizedFailure() => ScheduleErrorType.forbidden,
    InvalidCredentialsFailure() => ScheduleErrorType.invalidCredentials,
    ConflictFailure() => ScheduleErrorType.conflict,
    ServerFailure() => ScheduleErrorType.server,
    StorageFailure() => ScheduleErrorType.storage,
    AuthFailure() => ScheduleErrorType.auth,
    _ => ScheduleErrorType.unknown,
  };
}
