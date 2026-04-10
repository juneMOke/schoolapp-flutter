import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/usecases/clear_local_academic_year_use_case.dart';
import 'package:school_app_flutter/features/academic_year/domain/usecases/get_local_academic_year_use_case.dart';
import 'package:school_app_flutter/features/academic_year/domain/usecases/get_remote_academic_year_use_case.dart';
import 'package:school_app_flutter/features/academic_year/domain/usecases/save_local_academic_year_use_case.dart';

part 'academic_year_event.dart';
part 'academic_year_state.dart';

class AcademicYearBloc extends Bloc<AcademicYearEvent, AcademicYearState> {
  final GetRemoteAcademicYearUseCase _getRemoteAcademicYearUseCase;
  final GetLocalAcademicYearUseCase _getLocalAcademicYearUseCase;
  final SaveLocalAcademicYearUseCase _saveLocalAcademicYearUseCase;
  final ClearLocalAcademicYearUseCase _clearLocalAcademicYearUseCase;

  AcademicYearBloc({
    required GetRemoteAcademicYearUseCase getRemoteAcademicYearUseCase,
    required GetLocalAcademicYearUseCase getLocalAcademicYearUseCase,
    required SaveLocalAcademicYearUseCase saveLocalAcademicYearUseCase,
    required ClearLocalAcademicYearUseCase clearLocalAcademicYearUseCase,
  }) : _getRemoteAcademicYearUseCase = getRemoteAcademicYearUseCase,
       _getLocalAcademicYearUseCase = getLocalAcademicYearUseCase,
       _saveLocalAcademicYearUseCase = saveLocalAcademicYearUseCase,
       _clearLocalAcademicYearUseCase = clearLocalAcademicYearUseCase,
       super(const AcademicYearState.initial()) {
    on<AcademicYearRemoteRequested>(_onRemoteRequested);
    on<AcademicYearLocalRequested>(_onLocalRequested);
    on<AcademicYearResetRequested>(_onResetRequested);
    on<AcademicYearClearLocalRequested>(_onClearLocalRequested);
  }

  Future<void> _onRemoteRequested(
    AcademicYearRemoteRequested event,
    Emitter<AcademicYearState> emit,
  ) async {
    emit(state.copyWith(status: AcademicYearLoadStatus.loading, errorMessage: null));

    final result = await _getRemoteAcademicYearUseCase(schoolId: event.schoolId);

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: AcademicYearLoadStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (academicYear) async {
        await _saveLocalAcademicYearUseCase(academicYear: academicYear);
        emit(
          state.copyWith(
            status: AcademicYearLoadStatus.success,
            academicYear: academicYear,
            source: AcademicYearSource.remote,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> _onLocalRequested(
    AcademicYearLocalRequested event,
    Emitter<AcademicYearState> emit,
  ) async {
    emit(state.copyWith(status: AcademicYearLoadStatus.loading, errorMessage: null));

    final result = await _getLocalAcademicYearUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AcademicYearLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (academicYear) => emit(
        state.copyWith(
          status: AcademicYearLoadStatus.success,
          academicYear: academicYear,
          source: AcademicYearSource.local,
          errorMessage: null,
        ),
      ),
    );
  }

  FutureOr<void> _onResetRequested(
    AcademicYearResetRequested event,
    Emitter<AcademicYearState> emit,
  ) {
    emit(const AcademicYearState.initial());
  }

  Future<void> _onClearLocalRequested(
    AcademicYearClearLocalRequested event,
    Emitter<AcademicYearState> emit,
  ) async {
    final result = await _clearLocalAcademicYearUseCase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AcademicYearLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(const AcademicYearState.initial()),
    );
  }
}
