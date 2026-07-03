import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

/// Note persistée renvoyée par le `PUT` de saisie (réponse `NoteEvaluationDto`).
///
/// Contrairement à [NoteEleve] (ligne de grille), le [statut] est ici toujours
/// renseigné : la note existe puisqu'elle vient d'être enregistrée.
class NoteEvaluation extends Equatable {
  final String id;
  final String evaluationId;
  final String studentId;

  /// Points obtenus, `null` quand [statut] != NOTEE (backend l'a remis à null).
  final double? pointsObtenus;

  final StatutNote statut;

  const NoteEvaluation({
    required this.id,
    required this.evaluationId,
    required this.studentId,
    required this.statut,
    this.pointsObtenus,
  });

  @override
  List<Object?> get props => [
    id,
    evaluationId,
    studentId,
    pointsObtenus,
    statut,
  ];
}
