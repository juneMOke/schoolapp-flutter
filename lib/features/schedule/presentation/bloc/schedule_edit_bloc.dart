import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/create_session_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/create_time_slot_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/delete_session_usecase.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_edit_event.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_edit_state.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';

/// BLoC d'**écriture** de l'emploi du temps (surface conseil pédagogique /
/// admin) : création de créneaux, placement et retrait de séances.
///
/// Ne déclenche rien au montage : attend une action utilisateur et se prémunit
/// du double-envoi via [ScheduleEditStatus.submitting]. Le 409 (double-booking)
/// et le 400 (cours sans enseignant affecté) produisent des `errorType`
/// distincts (`conflict` / `validation`).
class ScheduleEditBloc extends Bloc<ScheduleEditEvent, ScheduleEditState> {
  final CreateTimeSlotUseCase _createTimeSlot;
  final CreateSessionUseCase _createSession;
  final DeleteSessionUseCase _deleteSession;

  ScheduleEditBloc({
    required CreateTimeSlotUseCase createTimeSlot,
    required CreateSessionUseCase createSession,
    required DeleteSessionUseCase deleteSession,
  }) : _createTimeSlot = createTimeSlot,
       _createSession = createSession,
       _deleteSession = deleteSession,
       super(const ScheduleEditState()) {
    on<TimeSlotCreated>(_onTimeSlotCreated);
    on<SessionCreated>(_onSessionCreated);
    on<SessionDeleted>(_onSessionDeleted);
    on<ScheduleEditReset>(_onReset);
  }

  Future<void> _onTimeSlotCreated(
    TimeSlotCreated event,
    Emitter<ScheduleEditState> emit,
  ) async {
    if (state.status == ScheduleEditStatus.submitting) return;
    _emitSubmitting(emit);

    final result = await _createTimeSlot(event.request);

    result.fold(
      (failure) => _emitFailure(emit, failure),
      (timeSlot) => emit(
        state.copyWith(
          status: ScheduleEditStatus.success,
          lastCreatedTimeSlot: timeSlot,
          lastCreatedSession: null,
          errorType: ScheduleErrorType.none,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onSessionCreated(
    SessionCreated event,
    Emitter<ScheduleEditState> emit,
  ) async {
    if (state.status == ScheduleEditStatus.submitting) return;
    _emitSubmitting(emit);

    final result = await _createSession(event.request);

    result.fold(
      (failure) => _emitFailure(emit, failure),
      (session) => emit(
        state.copyWith(
          status: ScheduleEditStatus.success,
          lastCreatedSession: session,
          lastCreatedTimeSlot: null,
          errorType: ScheduleErrorType.none,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onSessionDeleted(
    SessionDeleted event,
    Emitter<ScheduleEditState> emit,
  ) async {
    if (state.status == ScheduleEditStatus.submitting) return;
    _emitSubmitting(emit);

    final result = await _deleteSession(event.sessionId);

    result.fold(
      (failure) => _emitFailure(emit, failure),
      (_) => emit(
        state.copyWith(
          status: ScheduleEditStatus.success,
          lastCreatedTimeSlot: null,
          lastCreatedSession: null,
          errorType: ScheduleErrorType.none,
          errorMessage: null,
        ),
      ),
    );
  }

  void _onReset(ScheduleEditReset event, Emitter<ScheduleEditState> emit) {
    emit(const ScheduleEditState());
  }

  /// Émission `submitting` synchrone (avant le premier `await`) : une 2e
  /// soumission rapide voit bien l'état en cours et tombe dans la garde. On
  /// purge tout résultat/erreur d'un envoi précédent.
  void _emitSubmitting(Emitter<ScheduleEditState> emit) {
    emit(
      state.copyWith(
        status: ScheduleEditStatus.submitting,
        lastCreatedTimeSlot: null,
        lastCreatedSession: null,
        errorType: ScheduleErrorType.none,
        errorMessage: null,
      ),
    );
  }

  void _emitFailure(Emitter<ScheduleEditState> emit, Failure failure) {
    emit(
      state.copyWith(
        status: ScheduleEditStatus.failure,
        errorType: _mapFailureToErrorType(failure),
        errorMessage: failure.message,
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
    // HTTP 409 -> ConflictFailure -> conflict (double-booking enseignant/classe).
    ConflictFailure() => ScheduleErrorType.conflict,
    ServerFailure() => ScheduleErrorType.server,
    StorageFailure() => ScheduleErrorType.storage,
    AuthFailure() => ScheduleErrorType.auth,
    _ => ScheduleErrorType.unknown,
  };
}
