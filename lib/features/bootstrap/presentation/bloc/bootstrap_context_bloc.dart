import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/clear_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_local_bootstrap_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_current_year_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/get_remote_bootstrap_previous_year_use_case.dart';
import 'package:school_app_flutter/features/bootstrap/domain/usecases/save_local_bootstrap_use_case.dart';

part 'bootstrap_context_event.dart';
part 'bootstrap_context_state.dart';

/// Bloc générique pour un contexte bootstrap spécifique (current-year ou previous-year).
/// Peut être étendu pour créer des blocs contextuels.
abstract class BootstrapContextBloc<E extends BootstrapContextEvent>
    extends Bloc<E, BootstrapContextState> {
  final GetRemoteBootstrapCurrentYearUseCase? _getRemoteCurrentYearUseCase;
  final GetRemoteBootstrapPreviousYearUseCase? _getRemotePreviousYearUseCase;
  final GetLocalBootstrapUseCase _getLocalBootstrapUseCase;

  BootstrapContextBloc({
    GetRemoteBootstrapCurrentYearUseCase? getRemoteCurrentYearUseCase,
    GetRemoteBootstrapPreviousYearUseCase? getRemotePreviousYearUseCase,
    required GetLocalBootstrapUseCase getLocalBootstrapUseCase,
    required SaveLocalBootstrapUseCase saveLocalBootstrapUseCase,
    required ClearLocalBootstrapUseCase clearLocalBootstrapUseCase,
  }) : _getRemoteCurrentYearUseCase = getRemoteCurrentYearUseCase,
       _getRemotePreviousYearUseCase = getRemotePreviousYearUseCase,
       _getLocalBootstrapUseCase = getLocalBootstrapUseCase,
       super(const BootstrapContextState.initial());

  Future<void> onLoadRemoteCurrentYear(
    BootstrapContextRemoteCurrentYearRequested event,
    Emitter<BootstrapContextState> emit,
  ) async {
    if (_getRemoteCurrentYearUseCase == null) return;

    emit(state.copyWith(status: BootstrapContextLoadStatus.loading));

    final result = await _getRemoteCurrentYearUseCase();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: BootstrapContextLoadStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (bootstrap) async {
        emit(
          state.copyWith(
            status: BootstrapContextLoadStatus.success,
            bootstrap: bootstrap,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> onLoadRemotePreviousYear(
    BootstrapContextRemotePreviousYearRequested event,
    Emitter<BootstrapContextState> emit,
  ) async {
    if (_getRemotePreviousYearUseCase == null) return;

    emit(state.copyWith(status: BootstrapContextLoadStatus.loading));

    final result = await _getRemotePreviousYearUseCase();

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: BootstrapContextLoadStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (bootstrap) async {
        emit(
          state.copyWith(
            status: BootstrapContextLoadStatus.success,
            bootstrap: bootstrap,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> onLoadLocal(
    BootstrapContextLocalRequested event,
    Emitter<BootstrapContextState> emit,
  ) async {
    emit(state.copyWith(status: BootstrapContextLoadStatus.loading));

    final result = await _getLocalBootstrapUseCase(event.key);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BootstrapContextLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (bootstrap) => emit(
        state.copyWith(
          status: BootstrapContextLoadStatus.success,
          bootstrap: bootstrap,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> onReset(
    BootstrapContextResetRequested event,
    Emitter<BootstrapContextState> emit,
  ) {
    emit(const BootstrapContextState.initial());
    return Future.value();
  }
}
