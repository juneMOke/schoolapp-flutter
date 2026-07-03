import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/create_evaluation_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_state.dart';

/// BLoC d'écriture : création d'une évaluation sous un cours.
///
/// Contrairement aux BLoCs de lecture du module, il ne déclenche rien au
/// montage : il attend un [CreateEvaluationSubmitted] (action utilisateur) et
/// se prémunit du double envoi via [CreateEvaluationStatus.inProgress].
class CreateEvaluationBloc
    extends Bloc<CreateEvaluationEvent, CreateEvaluationState> {
  final CreateEvaluationUseCase _createEvaluationUseCase;

  CreateEvaluationBloc({
    required CreateEvaluationUseCase createEvaluationUseCase,
  }) : _createEvaluationUseCase = createEvaluationUseCase,
       super(const CreateEvaluationState()) {
    on<CreateEvaluationSubmitted>(_onSubmitted);
    on<CreateEvaluationReset>(_onReset);
  }

  Future<void> _onSubmitted(
    CreateEvaluationSubmitted event,
    Emitter<CreateEvaluationState> emit,
  ) async {
    // Garde anti-double-envoi : on ignore toute soumission tant qu'un appel
    // réseau est déjà en cours. L'émission `inProgress` est synchrone avant le
    // premier `await`, donc une 2e soumission rapide voit bien l'état en cours.
    if (state.status == CreateEvaluationStatus.inProgress) return;

    emit(
      state.copyWith(
        status: CreateEvaluationStatus.inProgress,
        // Invariant : createdEvaluation non-null ⟹ status success. On purge
        // donc tout résultat d'un envoi précédent dès qu'on resoumet.
        createdEvaluation: null,
        errorType: CreateEvaluationErrorType.none,
        errorMessage: null,
      ),
    );

    final result = await _createEvaluationUseCase(event.coursId, event.request);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CreateEvaluationStatus.failure,
          errorType: _mapFailureToErrorType(failure),
          errorMessage: failure.message,
        ),
      ),
      (evaluation) => emit(
        state.copyWith(
          status: CreateEvaluationStatus.success,
          createdEvaluation: evaluation,
          errorType: CreateEvaluationErrorType.none,
          errorMessage: null,
        ),
      ),
    );
  }

  void _onReset(
    CreateEvaluationReset event,
    Emitter<CreateEvaluationState> emit,
  ) {
    emit(const CreateEvaluationState());
  }

  CreateEvaluationErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => CreateEvaluationErrorType.network,
        NotFoundFailure() => CreateEvaluationErrorType.notFound,
        ValidationFailure() => CreateEvaluationErrorType.validation,
        // Convention projet (cf. interceptor Dio) : HTTP 403 ->
        // UnauthorizedFailure -> forbidden ; HTTP 401 ->
        // InvalidCredentialsFailure -> invalidCredentials.
        UnauthorizedFailure() => CreateEvaluationErrorType.forbidden,
        InvalidCredentialsFailure() =>
          CreateEvaluationErrorType.invalidCredentials,
        ServerFailure() => CreateEvaluationErrorType.server,
        StorageFailure() => CreateEvaluationErrorType.storage,
        AuthFailure() => CreateEvaluationErrorType.auth,
        _ => CreateEvaluationErrorType.unknown,
      };
}
