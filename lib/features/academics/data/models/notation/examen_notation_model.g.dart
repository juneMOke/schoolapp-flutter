// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'examen_notation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamenNotationModel _$ExamenNotationModelFromJson(Map<String, dynamic> json) =>
    ExamenNotationModel(
      evaluationId: json['evaluationId'] as String,
      nom: json['nom'] as String,
      date: DateTime.parse(json['date'] as String),
      poids: (json['poids'] as num).toInt(),
      maxPoints: (json['maxPoints'] as num).toDouble(),
      moyenneGenerale: (json['moyenneGenerale'] as num?)?.toDouble(),
      statutSaisie: json['statutSaisie'] as String,
      pourcentageSaisie: (json['pourcentageSaisie'] as num).toDouble(),
    );

Map<String, dynamic> _$ExamenNotationModelToJson(
  ExamenNotationModel instance,
) => <String, dynamic>{
  'evaluationId': instance.evaluationId,
  'nom': instance.nom,
  'date': instance.date.toIso8601String(),
  'poids': instance.poids,
  'maxPoints': instance.maxPoints,
  'moyenneGenerale': instance.moyenneGenerale,
  'statutSaisie': instance.statutSaisie,
  'pourcentageSaisie': instance.pourcentageSaisie,
};
