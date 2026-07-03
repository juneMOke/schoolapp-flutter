// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_groupe_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvaluationGroupeModel _$EvaluationGroupeModelFromJson(
  Map<String, dynamic> json,
) => EvaluationGroupeModel(
  type: json['type'] as String,
  evaluations: (json['evaluations'] as List<dynamic>)
      .map((e) => EvaluationSummaryModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$EvaluationGroupeModelToJson(
  EvaluationGroupeModel instance,
) => <String, dynamic>{
  'type': instance.type,
  'evaluations': instance.evaluations.map((e) => e.toJson()).toList(),
};
