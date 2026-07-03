import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_cours_notation_detail_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_state.dart';

class CoursNotationBloc extends Bloc<CoursNotationEvent, CoursNotationState> {
  final GetCoursNotationDetailUseCase _getCoursNotationDetailUseCase;

  CoursNotationBloc({
    required GetCoursNotationDetailUseCase getCoursNotationDetailUseCase,
  }) : _getCoursNotationDetailUseCase = getCoursNotationDetailUseCase,
       super(const CoursNotationState()) {
    on<CoursNotationRequested>(_onCoursNotationRequested);
  }

  Future<void> _onCoursNotationRequested(
    CoursNotationRequested event,
    Emitter<CoursNotationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CoursNotationStatus.loading,
        errorType: CoursNotationErrorType.none,
      ),
    );

    final result = await _getCoursNotationDetailUseCase(event.coursId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CoursNotationStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (detail) => emit(
        state.copyWith(
          status: CoursNotationStatus.success,
          detail: detail,
          errorType: CoursNotationErrorType.none,
        ),
      ),
    );
  }

  CoursNotationErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => CoursNotationErrorType.network,
        NotFoundFailure() => CoursNotationErrorType.notFound,
        ValidationFailure() => CoursNotationErrorType.validation,
        // Convention projet (cf. interceptor Dio) : HTTP 403 ->
        // UnauthorizedFailure -> forbidden ; HTTP 401 ->
        // InvalidCredentialsFailure -> invalidCredentials.
        UnauthorizedFailure() => CoursNotationErrorType.forbidden,
        InvalidCredentialsFailure() =>
          CoursNotationErrorType.invalidCredentials,
        ServerFailure() => CoursNotationErrorType.server,
        StorageFailure() => CoursNotationErrorType.storage,
        AuthFailure() => CoursNotationErrorType.auth,
        _ => CoursNotationErrorType.unknown,
      };
}
