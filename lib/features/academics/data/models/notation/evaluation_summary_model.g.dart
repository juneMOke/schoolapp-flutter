// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvaluationSummaryModel _$EvaluationSummaryModelFromJson(
  Map<String, dynamic> json,
) => EvaluationSummaryModel(
  id: json['id'] as String,
  type: json['type'] as String,
  nom: json['nom'] as String,
  chapitres: (json['chapitres'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  date: DateTime.parse(json['date'] as String),
  maxPoints: (json['maxPoints'] as num).toDouble(),
  poids: (json['poids'] as num).toInt(),
  statutSaisie: json['statutSaisie'] as String,
  pourcentageSaisie: (json['pourcentageSaisie'] as num).toDouble(),
);

Map<String, dynamic> _$EvaluationSummaryModelToJson(
  EvaluationSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'nom': instance.nom,
  'chapitres': instance.chapitres,
  'date': instance.date.toIso8601String(),
  'maxPoints': instance.maxPoints,
  'poids': instance.poids,
  'statutSaisie': instance.statutSaisie,
  'pourcentageSaisie': instance.pourcentageSaisie,
};
