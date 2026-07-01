import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_my_courses_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final GetMyCoursesUseCase _getMyCoursesUseCase;

  CourseBloc({required GetMyCoursesUseCase getMyCoursesUseCase})
    : _getMyCoursesUseCase = getMyCoursesUseCase,
      super(const CourseState()) {
    on<MyCoursesRequested>(_onMyCoursesRequested);
  }

  Future<void> _onMyCoursesRequested(
    MyCoursesRequested event,
    Emitter<CourseState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CourseStatus.loading,
        errorType: CourseErrorType.none,
      ),
    );

    final result = await _getMyCoursesUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CourseStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (courses) => emit(
        state.copyWith(
          status: CourseStatus.success,
          courses: courses,
          errorType: CourseErrorType.none,
        ),
      ),
    );
  }

  CourseErrorType _mapFailureToErrorType(Failure failure) => switch (failure) {
    NetworkFailure() => CourseErrorType.network,
    NotFoundFailure() => CourseErrorType.notFound,
    ValidationFailure() => CourseErrorType.validation,
    // Convention projet (cf. interceptor Dio) : HTTP 403 -> UnauthorizedFailure
    // -> forbidden ; HTTP 401 -> InvalidCredentialsFailure -> invalidCredentials.
    UnauthorizedFailure() => CourseErrorType.forbidden,
    InvalidCredentialsFailure() => CourseErrorType.invalidCredentials,
    ServerFailure() => CourseErrorType.server,
    StorageFailure() => CourseErrorType.storage,
    AuthFailure() => CourseErrorType.auth,
    _ => CourseErrorType.unknown,
  };
}
