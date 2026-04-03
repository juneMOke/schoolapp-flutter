import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/clear_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/save_local_bootstrap_use_case.dart';

part 'bootstrap_event.dart';
part 'bootstrap_state.dart';

class BootstrapBloc extends Bloc<BootstrapEvent, BootstrapState> {
  final GetRemoteBootstrapUseCase _getRemoteBootstrapUseCase;
  final GetLocalBootstrapUseCase _getLocalBootstrapUseCase;
  final SaveLocalBootstrapUseCase _saveLocalBootstrapUseCase;
  final ClearLocalBootstrapUseCase _clearLocalBootstrapUseCase;

  BootstrapBloc({
    required GetRemoteBootstrapUseCase getRemoteBootstrapUseCase,
    required GetLocalBootstrapUseCase getLocalBootstrapUseCase,
    required SaveLocalBootstrapUseCase saveLocalBootstrapUseCase,
    required ClearLocalBootstrapUseCase clearLocalBootstrapUseCase,
  }) : _getRemoteBootstrapUseCase = getRemoteBootstrapUseCase,
       _getLocalBootstrapUseCase = getLocalBootstrapUseCase,
       _saveLocalBootstrapUseCase = saveLocalBootstrapUseCase,
       _clearLocalBootstrapUseCase = clearLocalBootstrapUseCase,
       super(const BootstrapState.initial()) {
    on<BootstrapRemoteRequested>(_onRemoteRequested);
    on<BootstrapLocalRequested>(_onLocalRequested);
    on<BootstrapResetRequested>(_onResetRequested);
    on<BootstrapClearLocalRequested>(_onClearLocalRequested);
  }

  Future<void> _onRemoteRequested(
    BootstrapRemoteRequested event,
    Emitter<BootstrapState> emit,
  ) async {
    emit(
      state.copyWith(status: BootstrapLoadStatus.loading, errorMessage: null),
    );

    final result = await _getRemoteBootstrapUseCase();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: BootstrapLoadStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (bootstrap) async {
        await _saveLocalBootstrapUseCase(bootstrap: bootstrap);
        emit(
          state.copyWith(
            status: BootstrapLoadStatus.success,
            bootstrap: bootstrap,
            source: BootstrapSource.remote,
            errorMessage: null,
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
      state.copyWith(status: BootstrapLoadStatus.loading, errorMessage: null),
    );

    final result = await _getLocalBootstrapUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BootstrapLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (bootstrap) => emit(
        state.copyWith(
          status: BootstrapLoadStatus.success,
          bootstrap: bootstrap,
          source: BootstrapSource.local,
          errorMessage: null,
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
    final result = await _clearLocalBootstrapUseCase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BootstrapLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(const BootstrapState.initial()),
    );
  }
}
