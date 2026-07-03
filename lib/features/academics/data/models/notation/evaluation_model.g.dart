// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvaluationModel _$EvaluationModelFromJson(Map<String, dynamic> json) =>
    EvaluationModel(
      id: json['id'] as String,
      coursId: json['coursId'] as String,
      type: json['type'] as String,
      date: DateOnlyJsonHelper.fromJson(json['date'] as String),
      maxPoints: (json['maxPoints'] as num).toDouble(),
      poids: (json['poids'] as num).toInt(),
      sousPeriodeId: json['sousPeriodeId'] as String?,
      periodeScolaireId: json['periodeScolaireId'] as String?,
      chapitreIds:
          (json['chapitreIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$EvaluationModelToJson(EvaluationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'coursId': instance.coursId,
      'type': instance.type,
      'date': DateOnlyJsonHelper.toJson(instance.date),
      'maxPoints': instance.maxPoints,
      'poids': instance.poids,
      'sousPeriodeId': instance.sousPeriodeId,
      'periodeScolaireId': instance.periodeScolaireId,
      'chapitreIds': instance.chapitreIds,
    };
