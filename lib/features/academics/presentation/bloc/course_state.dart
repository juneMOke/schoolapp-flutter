import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';

enum CourseStatus { initial, loading, success, failure }

/// Type d'erreur exposé au UI pour réagir en conséquence (réseau, 404, 403…).
enum CourseErrorType {
  none,
  network,
  notFound,
  validation,
  // HTTP 403 -> UnauthorizedFailure -> forbidden (convention projet). Pas de
  // valeur `unauthorized` : elle ne serait jamais émise par le BLoC.
  forbidden,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown;

  /// Le type d'erreur d'une [Failure]. Convention projet (cf. intercepteur
  /// Dio) : HTTP 403 -> [UnauthorizedFailure] -> forbidden ; HTTP 401 ->
  /// [InvalidCredentialsFailure] -> invalidCredentials.
  static CourseErrorType of(Failure failure) => switch (failure) {
    NetworkFailure() => CourseErrorType.network,
    NotFoundFailure() => CourseErrorType.notFound,
    ValidationFailure() => CourseErrorType.validation,
    UnauthorizedFailure() => CourseErrorType.forbidden,
    InvalidCredentialsFailure() => CourseErrorType.invalidCredentials,
    ServerFailure() => CourseErrorType.server,
    StorageFailure() => CourseErrorType.storage,
    AuthFailure() => CourseErrorType.auth,
    _ => CourseErrorType.unknown,
  };
}

class CourseState extends Equatable {
  final CourseStatus status;
  final List<CourseSummary> courses;
  final CourseErrorType errorType;

  const CourseState({
    this.status = CourseStatus.initial,
    this.courses = const [],
    this.errorType = CourseErrorType.none,
  });

  CourseState copyWith({
    CourseStatus? status,
    List<CourseSummary>? courses,
    CourseErrorType? errorType,
  }) => CourseState(
    status: status ?? this.status,
    courses: courses ?? this.courses,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, courses, errorType];
}
