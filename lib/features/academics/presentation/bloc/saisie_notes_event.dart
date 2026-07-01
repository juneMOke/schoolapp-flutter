import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

sealed class SaisieNotesEvent extends Equatable {
  const SaisieNotesEvent();
}

/// Charge la grille de saisie de l'évaluation [evaluationId].
///
/// [maxPoints] (barème de l'évaluation, connu de l'écran via l'`EvaluationDto`
/// déjà chargé) est transmis ici pour permettre la validation locale
/// `0 ≤ points ≤ maxPoints` avant tout appel réseau (cf. [NoteSaisie]).
class NotesElevesLoaded extends SaisieNotesEvent {
  final String evaluationId;
  final double maxPoints;

  const NotesElevesLoaded({
    required this.evaluationId,
    required this.maxPoints,
  });

  @override
  List<Object?> get props => [evaluationId, maxPoints];
}

/// Saisit/rattrape la note de l'élève [studentId] pour l'évaluation
/// [evaluationId].
///
/// [pointsObtenus] n'est pertinent que si [statut] == [StatutNote.notee] (il est
/// ignoré pour les autres statuts). Le BLoC valide localement avant l'appel
/// réseau et verrouille la ligne pendant l'enregistrement (anti-course).
class NoteSaisie extends SaisieNotesEvent {
  final String evaluationId;
  final String studentId;
  final StatutNote statut;
  final double? pointsObtenus;

  const NoteSaisie({
    required this.evaluationId,
    required this.studentId,
    required this.statut,
    this.pointsObtenus,
  });

  @override
  List<Object?> get props => [evaluationId, studentId, statut, pointsObtenus];
}
