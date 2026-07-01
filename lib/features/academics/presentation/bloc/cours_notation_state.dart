import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';

enum CoursNotationStatus { initial, loading, success, failure }

/// Type d'erreur exposé au UI pour réagir en conséquence (réseau, 404, 403…).
enum CoursNotationErrorType {
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
  unknown,
}

/// Sentinelle pour distinguer « champ non fourni » de « remis à null » dans
/// [CoursNotationState.copyWith] (convention projet pour les champs nullable).
const _undefined = Object();

class CoursNotationState extends Equatable {
  final CoursNotationStatus status;
  final CoursNotationDetail? detail;
  final CoursNotationErrorType errorType;

  const CoursNotationState({
    this.status = CoursNotationStatus.initial,
    this.detail,
    this.errorType = CoursNotationErrorType.none,
  });

  CoursNotationState copyWith({
    CoursNotationStatus? status,
    Object? detail = _undefined,
    CoursNotationErrorType? errorType,
  }) => CoursNotationState(
    status: status ?? this.status,
    detail: identical(detail, _undefined)
        ? this.detail
        : detail as CoursNotationDetail?,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, detail, errorType];
}
