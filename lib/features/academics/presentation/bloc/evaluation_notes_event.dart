import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';

sealed class EvaluationNotesEvent extends Equatable {
  const EvaluationNotesEvent();
}

/// Demande le chargement des notes de chaque élève pour l'évaluation
/// [evaluationId] (consultation en lecture seule).
///
/// Émis au montage de la feature. [evaluation] est l'en-tête déjà connu de
/// l'écran appelant (barème `maxPoints`, type, date) : il est optionnel et n'est
/// PAS rechargé — le BLoC ne fait qu'un seul appel réseau (`getNotesEleves`).
class EvaluationNotesRequested extends EvaluationNotesEvent {
  final String evaluationId;

  /// En-tête déjà disponible côté appelant, ou `null` si non transmis.
  final Evaluation? evaluation;

  const EvaluationNotesRequested({required this.evaluationId, this.evaluation});

  @override
  List<Object?> get props => [evaluationId, evaluation];
}
