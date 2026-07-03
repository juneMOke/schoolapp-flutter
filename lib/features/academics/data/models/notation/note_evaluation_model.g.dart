// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_evaluation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteEvaluationModel _$NoteEvaluationModelFromJson(Map<String, dynamic> json) =>
    NoteEvaluationModel(
      id: json['id'] as String,
      evaluationId: json['evaluationId'] as String,
      studentId: json['studentId'] as String,
      statut: json['statut'] as String,
      pointsObtenus: (json['pointsObtenus'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$NoteEvaluationModelToJson(
  NoteEvaluationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'evaluationId': instance.evaluationId,
  'studentId': instance.studentId,
  'pointsObtenus': instance.pointsObtenus,
  'statut': instance.statut,
};
