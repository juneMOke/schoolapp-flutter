import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/evaluation_notes_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/evaluation_notes_state.dart';

/// Consultation en lecture seule des notes de chaque élève pour une évaluation.
///
/// Distinct de `SaisieNotesBloc` (édition) : ici aucun `PUT`, aucun statut par
/// ligne. Un seul appel réseau (`getNotesEleves`, même endpoint que la grille de
/// saisie) ; l'en-tête (`Evaluation`) est fourni par l'écran appelant via
/// l'event, jamais rechargé.
class EvaluationNotesBloc
    extends Bloc<EvaluationNotesEvent, EvaluationNotesState> {
  final GetNotesElevesUseCase _getNotesElevesUseCase;

  EvaluationNotesBloc({required GetNotesElevesUseCase getNotesElevesUseCase})
    : _getNotesElevesUseCase = getNotesElevesUseCase,
      super(const EvaluationNotesState()) {
    on<EvaluationNotesRequested>(_onEvaluationNotesRequested);
  }

  Future<void> _onEvaluationNotesRequested(
    EvaluationNotesRequested event,
    Emitter<EvaluationNotesState> emit,
  ) async {
    // On pose l'en-tête déjà connu dès le chargement : l'UI peut l'afficher
    // pendant que la liste des notes se charge.
    emit(
      state.copyWith(
        status: EvaluationNotesStatus.loading,
        evaluation: event.evaluation,
        errorType: EvaluationNotesErrorType.none,
      ),
    );

    final result = await _getNotesElevesUseCase(event.evaluationId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EvaluationNotesStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (notes) => emit(
        state.copyWith(
          status: EvaluationNotesStatus.success,
          notes: notes,
          errorType: EvaluationNotesErrorType.none,
        ),
      ),
    );
  }

  EvaluationNotesErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => EvaluationNotesErrorType.network,
        NotFoundFailure() => EvaluationNotesErrorType.notFound,
        ValidationFailure() => EvaluationNotesErrorType.validation,
        // Convention projet (cf. interceptor Dio) : HTTP 403 ->
        // UnauthorizedFailure -> forbidden ; HTTP 401 ->
        // InvalidCredentialsFailure -> invalidCredentials.
        UnauthorizedFailure() => EvaluationNotesErrorType.forbidden,
        InvalidCredentialsFailure() =>
          EvaluationNotesErrorType.invalidCredentials,
        ServerFailure() => EvaluationNotesErrorType.server,
        StorageFailure() => EvaluationNotesErrorType.storage,
        AuthFailure() => EvaluationNotesErrorType.auth,
        _ => EvaluationNotesErrorType.unknown,
      };
}
