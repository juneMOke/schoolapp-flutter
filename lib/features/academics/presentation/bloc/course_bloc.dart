import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_my_courses_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final GetMyCoursesUseCase _getMyCoursesUseCase;

  /// Numéro de la dernière lecture émise — les handlers de types d'événements
  /// différents s'exécutent en parallèle dans bloc, donc une relecture
  /// déclenchée par un pull peut devancer la lecture initiale partie sur un
  /// cache vide. Sans ce garde, cette dernière écraserait la liste fraîche.
  int _readGeneration = 0;

  CourseBloc({required GetMyCoursesUseCase getMyCoursesUseCase})
    : _getMyCoursesUseCase = getMyCoursesUseCase,
      super(const CourseState()) {
    on<MyCoursesRequested>(_onMyCoursesRequested);
    on<MyCoursesRefreshRequested>(_onMyCoursesRefreshRequested);
  }

  /// Relecture silencieuse après un pull : pas de bascule en `loading` (la
  /// liste affichée clignoterait) ni en `failure` (une liste correcte ne doit
  /// pas devenir un écran d'erreur sur une relecture que l'utilisateur n'a pas
  /// demandée).
  Future<void> _onMyCoursesRefreshRequested(
    MyCoursesRefreshRequested event,
    Emitter<CourseState> emit,
  ) async {
    final generation = ++_readGeneration;
    final result = await _getMyCoursesUseCase();
    if (generation != _readGeneration) return; // lecture dépassée

    result.fold(
      (_) {},
      (courses) => emit(
        state.copyWith(
          status: CourseStatus.success,
          courses: courses,
          errorType: CourseErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onMyCoursesRequested(
    MyCoursesRequested event,
    Emitter<CourseState> emit,
  ) async {
    final generation = ++_readGeneration;
    emit(
      state.copyWith(
        status: CourseStatus.loading,
        errorType: CourseErrorType.none,
      ),
    );

    final result = await _getMyCoursesUseCase();
    if (generation != _readGeneration) return; // lecture dépassée

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
