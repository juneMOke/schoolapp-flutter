import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';

enum EvaluationNotesStatus { initial, loading, success, failure }

/// Type d'erreur exposé au UI pour réagir en conséquence (réseau, 404, 403…).
/// Aligné sur la convention du module (cf. `CoursNotationErrorType`).
enum EvaluationNotesErrorType {
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
/// [EvaluationNotesState.copyWith] (convention projet pour les champs nullable).
const _undefined = Object();

/// État de la consultation (lecture seule) des notes d'une évaluation.
class EvaluationNotesState extends Equatable {
  final EvaluationNotesStatus status;

  /// En-tête de l'évaluation (barème `maxPoints`, type, date) fourni par l'écran
  /// appelant. `null` quand le contexte ne l'a pas transmis : l'UI masque alors
  /// l'en-tête (mode dégradé). Cette feature ne recharge jamais l'en-tête.
  final Evaluation? evaluation;

  /// Notes de chaque élève de la classe du cours (déjà triées côté backend par
  /// nom puis prénom). Un élève non encore noté a `pointsObtenus`/`statut` nuls.
  final List<NoteEleve> notes;

  final EvaluationNotesErrorType errorType;

  const EvaluationNotesState({
    this.status = EvaluationNotesStatus.initial,
    this.evaluation,
    this.notes = const [],
    this.errorType = EvaluationNotesErrorType.none,
  });

  EvaluationNotesState copyWith({
    EvaluationNotesStatus? status,
    Object? evaluation = _undefined,
    List<NoteEleve>? notes,
    EvaluationNotesErrorType? errorType,
  }) => EvaluationNotesState(
    status: status ?? this.status,
    evaluation: identical(evaluation, _undefined)
        ? this.evaluation
        : evaluation as Evaluation?,
    notes: notes ?? this.notes,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, evaluation, notes, errorType];
}
