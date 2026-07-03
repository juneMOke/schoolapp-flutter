import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

part 'note_evaluation_model.g.dart';

/// Modèle de la réponse `NoteEvaluationDto` (retour du `PUT` de saisie) : la
/// note persistée.
///
/// [statut] est toujours renseigné ici (la note existe) : conservé en `String`
/// et converti en domaine via `fromApiValue` (repli `unknown` par résilience).
@JsonSerializable()
class NoteEvaluationModel extends Equatable {
  final String id;
  final String evaluationId;
  final String studentId;
  final double? pointsObtenus;
  final String statut;

  const NoteEvaluationModel({
    required this.id,
    required this.evaluationId,
    required this.studentId,
    required this.statut,
    this.pointsObtenus,
  });

  factory NoteEvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$NoteEvaluationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NoteEvaluationModelToJson(this);

  NoteEvaluation toEntity() => NoteEvaluation(
    id: id,
    evaluationId: evaluationId,
    studentId: studentId,
    pointsObtenus: pointsObtenus,
    statut: StatutNoteX.fromApiValue(statut),
  );

  @override
  List<Object?> get props => [
    id,
    evaluationId,
    studentId,
    pointsObtenus,
    statut,
  ];
}
