import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';

/// États de la création d'une évaluation.
///
/// `inProgress` correspond à l'appel réseau en cours (l'UI désactive le bouton
/// et bloque le double envoi) ; `success` porte l'évaluation créée.
enum CreateEvaluationStatus { initial, inProgress, success, failure }

/// Type d'erreur exposé au UI pour réagir (réseau, 400, 404, 403…). Aligné sur
/// la convention du module (cf. `CourseErrorType` / `CoursNotationErrorType`).
enum CreateEvaluationErrorType {
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
/// [CreateEvaluationState.copyWith] (convention projet pour les champs
/// nullable).
const _undefined = Object();

class CreateEvaluationState extends Equatable {
  final CreateEvaluationStatus status;

  /// Évaluation créée, renseignée uniquement en cas de succès.
  final Evaluation? createdEvaluation;

  final CreateEvaluationErrorType errorType;

  /// Message d'erreur remonté (corps backend si présent). Null hors échec.
  final String? errorMessage;

  const CreateEvaluationState({
    this.status = CreateEvaluationStatus.initial,
    this.createdEvaluation,
    this.errorType = CreateEvaluationErrorType.none,
    this.errorMessage,
  });

  bool get isInProgress => status == CreateEvaluationStatus.inProgress;

  CreateEvaluationState copyWith({
    CreateEvaluationStatus? status,
    Object? createdEvaluation = _undefined,
    CreateEvaluationErrorType? errorType,
    Object? errorMessage = _undefined,
  }) => CreateEvaluationState(
    status: status ?? this.status,
    createdEvaluation: identical(createdEvaluation, _undefined)
        ? this.createdEvaluation
        : createdEvaluation as Evaluation?,
    errorType: errorType ?? this.errorType,
    errorMessage: identical(errorMessage, _undefined)
        ? this.errorMessage
        : errorMessage as String?,
  );

  @override
  List<Object?> get props => [
    status,
    createdEvaluation,
    errorType,
    errorMessage,
  ];
}
