import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_resultats_classe_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_classe_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

/// BLoC de **lecture** de la vue classe (table roster × sous-période + synthèse).
///
/// Ne déclenche rien au montage : attend un [ResultatsClasseRequested]. Les `%`
/// `null` et les lignes `nonClasse` sont normaux — jamais traités comme erreur.
class ResultatsClasseBloc
    extends Bloc<ResultatsClasseEvent, ResultatsClasseState> {
  final GetResultatsClasseUseCase _getResultatsClasse;

  ResultatsClasseBloc({required GetResultatsClasseUseCase getResultatsClasse})
    : _getResultatsClasse = getResultatsClasse,
      super(const ResultatsClasseState()) {
    on<ResultatsClasseRequested>(_onResultatsClasseRequested);
  }

  Future<void> _onResultatsClasseRequested(
    ResultatsClasseRequested event,
    Emitter<ResultatsClasseState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ResultatsClasseStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
    );

    final result = await _getResultatsClasse(
      GetResultatsClasseParams(
        classroomId: event.classroomId,
        periodeScolaireId: event.periodeScolaireId,
        seuil: event.seuil,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ResultatsClasseStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (resultats) {
        // Vide = classe sans élève à afficher (aucune ligne ou effectif nul) :
        // état vide « classe », distinct d'un échec.
        final isEmpty =
            resultats.lignes.isEmpty || resultats.stats.effectif == 0;
        emit(
          state.copyWith(
            status: isEmpty
                ? ResultatsClasseStatus.empty
                : ResultatsClasseStatus.success,
            resultats: resultats,
            errorType: ResultatsErrorType.none,
          ),
        );
      },
    );
  }

  ResultatsErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => ResultatsErrorType.network,
        NotFoundFailure() => ResultatsErrorType.notFound,
        ValidationFailure() => ResultatsErrorType.validation,
        // Convention projet (cf. interceptor Dio) : HTTP 403 ->
        // UnauthorizedFailure -> forbidden ; HTTP 401 ->
        // InvalidCredentialsFailure -> invalidCredentials.
        UnauthorizedFailure() => ResultatsErrorType.forbidden,
        InvalidCredentialsFailure() => ResultatsErrorType.invalidCredentials,
        ServerFailure() => ResultatsErrorType.server,
        StorageFailure() => ResultatsErrorType.storage,
        AuthFailure() => ResultatsErrorType.auth,
        _ => ResultatsErrorType.unknown,
      };
}
