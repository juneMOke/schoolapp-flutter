import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/clear_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_current_year_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_previous_year_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/save_local_bootstrap_use_case.dart';

part 'bootstrap_event.dart';
part 'bootstrap_state.dart';

class BootstrapBloc extends Bloc<BootstrapEvent, BootstrapState> {
  final GetRemoteBootstrapCurrentYearUseCase _getRemoteBootstrapUseCase;
  final GetRemoteBootstrapPreviousYearUseCase
  _getRemoteBootstrapPreviousYearUseCase;
  final GetLocalBootstrapUseCase _getLocalBootstrapUseCase;
  final SaveLocalBootstrapUseCase _saveLocalBootstrapUseCase;
  final ClearLocalBootstrapUseCase _clearLocalBootstrapUseCase;

  BootstrapBloc({
    required GetRemoteBootstrapCurrentYearUseCase getRemoteBootstrapUseCase,
    required GetRemoteBootstrapPreviousYearUseCase
    getRemoteBootstrapPreviousYearUseCase,
    required GetLocalBootstrapUseCase getLocalBootstrapUseCase,
    required SaveLocalBootstrapUseCase saveLocalBootstrapUseCase,
    required ClearLocalBootstrapUseCase clearLocalBootstrapUseCase,
  }) : _getRemoteBootstrapUseCase = getRemoteBootstrapUseCase,
       _getRemoteBootstrapPreviousYearUseCase =
           getRemoteBootstrapPreviousYearUseCase,
       _getLocalBootstrapUseCase = getLocalBootstrapUseCase,
       _saveLocalBootstrapUseCase = saveLocalBootstrapUseCase,
       _clearLocalBootstrapUseCase = clearLocalBootstrapUseCase,
       super(const BootstrapState.initial()) {
    on<BootstrapRemoteCurrentYearRequested>(_onRemoteCurrentYearRequested);
    on<BootstrapRemotePreviousYearRequested>(_onRemotePreviousYearRequested);
    on<BootstrapRetryRequested>(_onRetryRequested);
    on<BootstrapLocalRequested>(_onLocalRequested);
    on<BootstrapResetRequested>(_onResetRequested);
    on<BootstrapClearLocalRequested>(_onClearLocalRequested);
  }

  /// Relance le bootstrap distant après un échec (réessai depuis le splash).
  /// Le trigger des fetch distants reste interne au bloc.
  void _onRetryRequested(
    BootstrapRetryRequested event,
    Emitter<BootstrapState> emit,
  ) {
    add(const BootstrapRemoteCurrentYearRequested());
    add(const BootstrapRemotePreviousYearRequested());
  }

  /// Un échec d'authentification (401/403) signifie que la session n'est plus
  /// valide côté serveur → main.dart déclenchera un logout.
  bool _isAuthFailure(Failure failure) =>
      failure is InvalidCredentialsFailure || failure is UnauthorizedFailure;

  Future<void> _onRemoteCurrentYearRequested(
    BootstrapRemoteCurrentYearRequested event,
    Emitter<BootstrapState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BootstrapLoadStatus.loading,
        errorMessage: null,
        operation: BootstrapOperation.remoteCurrentYear,
        sessionExpired: false,
      ),
    );

    final result = await _getRemoteBootstrapUseCase();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: BootstrapLoadStatus.failure,
            errorMessage: failure.message,
            operation: BootstrapOperation.remoteCurrentYear,
            sessionExpired: _isAuthFailure(failure),
          ),
        );
      },
      (bootstrap) async {
        await _saveLocalBootstrapUseCase(
          bootstrap: bootstrap,
          key: AppConstants.bootstrapPayloadKey,
        );
        emit(
          state.copyWith(
            status: BootstrapLoadStatus.success,
            bootstrap: bootstrap,
            source: BootstrapSource.remote,
            errorMessage: null,
            operation: BootstrapOperation.remoteCurrentYear,
            sessionExpired: false,
          ),
        );
      },
    );
  }

  Future<void> _onRemotePreviousYearRequested(
    BootstrapRemotePreviousYearRequested event,
    Emitter<BootstrapState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BootstrapLoadStatus.loading,
        errorMessage: null,
        operation: BootstrapOperation.remotePreviousYear,
        sessionExpired: false,
      ),
    );

    final result = await _getRemoteBootstrapPreviousYearUseCase();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: BootstrapLoadStatus.failure,
            errorMessage: failure.message,
            operation: BootstrapOperation.remotePreviousYear,
            sessionExpired: _isAuthFailure(failure),
          ),
        );
      },
      (bootstrap) async {
        await _saveLocalBootstrapUseCase(
          bootstrap: bootstrap,
          key: AppConstants.bootstrapPreviousYearPayloadKey,
        );
        emit(
          state.copyWith(
            status: BootstrapLoadStatus.success,
            bootstrap: bootstrap,
            source: BootstrapSource.remote,
            errorMessage: null,
            operation: BootstrapOperation.remotePreviousYear,
            sessionExpired: false,
          ),
        );
      },
    );
  }

  Future<void> _onLocalRequested(
    BootstrapLocalRequested event,
    Emitter<BootstrapState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BootstrapLoadStatus.loading,
        errorMessage: null,
        operation: BootstrapOperation.local,
      ),
    );

    final result = await _getLocalBootstrapUseCase(event.key);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BootstrapLoadStatus.failure,
          errorMessage: failure.message,
          operation: BootstrapOperation.local,
        ),
      ),
      (bootstrap) => emit(
        state.copyWith(
          status: BootstrapLoadStatus.success,
          bootstrap: bootstrap,
          source: BootstrapSource.local,
          errorMessage: null,
          operation: BootstrapOperation.local,
        ),
      ),
    );
  }

  FutureOr<void> _onResetRequested(
    BootstrapResetRequested event,
    Emitter<BootstrapState> emit,
  ) {
    emit(const BootstrapState.initial());
  }

  Future<void> _onClearLocalRequested(
    BootstrapClearLocalRequested event,
    Emitter<BootstrapState> emit,
  ) async {
    final result = await _clearLocalBootstrapUseCase(event.key);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BootstrapLoadStatus.failure,
          errorMessage: failure.message,
          operation: BootstrapOperation.clearLocal,
        ),
      ),
      (_) => emit(const BootstrapState.initial()),
    );
  }
}
