import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_context_repository.dart';

part 'academic_year_previous_context_event.dart';
part 'academic_year_previous_context_state.dart';

/// Contexte académique **précédent** (RE/PRE) — remplace
/// `BootstrapPreviousYearBloc`. `context == null` en succès = pas d'année
/// antérieure connue (école dans sa première année), un état légitime.
/// Jamais un gate de navigation (contrairement à [AcademicYearContextBloc]) —
/// suppose le référentiel déjà résolu par ce dernier.
class AcademicYearPreviousContextBloc
    extends
        Bloc<
          AcademicYearPreviousContextEvent,
          AcademicYearPreviousContextState
        > {
  final AcademicYearContextRepository _repository;

  AcademicYearPreviousContextBloc({
    required AcademicYearContextRepository repository,
  }) : _repository = repository,
       super(const AcademicYearPreviousContextState.initial()) {
    on<AcademicYearPreviousContextRequested>(_onRequested);
  }

  Future<void> _onRequested(
    AcademicYearPreviousContextRequested event,
    Emitter<AcademicYearPreviousContextState> emit,
  ) async {
    emit(state.copyWith(status: AcademicYearPreviousContextLoadStatus.loading));
    final result = await _repository.loadPreviousContext();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AcademicYearPreviousContextLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (context) => emit(
        state.copyWith(
          status: AcademicYearPreviousContextLoadStatus.success,
          context: context,
          errorMessage: null,
        ),
      ),
    );
  }
}
