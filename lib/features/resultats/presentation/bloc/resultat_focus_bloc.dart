import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_resultat_focus_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultat_focus_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

/// BLoC de **lecture** de la vue focus d'un élève.
///
/// Ne déclenche rien au montage : attend un [ResultatFocusRequested]. Un
/// `bulletinParDomaine` / `application` / `conduite` `null` est un cas valide,
/// jamais traité comme une erreur.
class ResultatFocusBloc extends Bloc<ResultatFocusEvent, ResultatFocusState> {
  final GetResultatFocusUseCase _getResultatFocus;

  ResultatFocusBloc({required GetResultatFocusUseCase getResultatFocus})
    : _getResultatFocus = getResultatFocus,
      super(const ResultatFocusState()) {
    on<ResultatFocusRequested>(_onResultatFocusRequested);
  }

  Future<void> _onResultatFocusRequested(
    ResultatFocusRequested event,
    Emitter<ResultatFocusState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ResultatFocusStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
    );

    final result = await _getResultatFocus(
      GetResultatFocusParams(
        classroomId: event.classroomId,
        periodeScolaireId: event.periodeScolaireId,
        studentId: event.studentId,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ResultatFocusStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (focus) => emit(
        state.copyWith(
          status: ResultatFocusStatus.success,
          focus: focus,
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
