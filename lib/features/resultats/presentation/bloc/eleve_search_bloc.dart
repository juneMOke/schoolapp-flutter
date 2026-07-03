import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/search_roster_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

/// BLoC de la recherche « Par élève » (roster scopé classe).
///
/// Ne déclenche rien au montage : attend un [EleveSearchRequested]. Une liste
/// vide donne l'état [EleveSearchStatus.empty], distinct d'un échec.
class EleveSearchBloc extends Bloc<EleveSearchEvent, EleveSearchState> {
  final SearchRosterUseCase _searchRoster;

  EleveSearchBloc({required SearchRosterUseCase searchRoster})
    : _searchRoster = searchRoster,
      super(const EleveSearchState()) {
    on<EleveSearchRequested>(_onEleveSearchRequested);
  }

  Future<void> _onEleveSearchRequested(
    EleveSearchRequested event,
    Emitter<EleveSearchState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EleveSearchStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
    );

    final result = await _searchRoster(
      SearchRosterParams(
        classroomId: event.classroomId,
        academicYearId: event.academicYearId,
        nom: event.nom,
        postnom: event.postnom,
        prenom: event.prenom,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: EleveSearchStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (eleves) => emit(
        state.copyWith(
          status: eleves.isEmpty
              ? EleveSearchStatus.empty
              : EleveSearchStatus.success,
          resultats: eleves,
          errorType: ResultatsErrorType.none,
        ),
      ),
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
