// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultats_classe_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultatsClasseStatsModel _$ResultatsClasseStatsModelFromJson(
  Map<String, dynamic> json,
) => ResultatsClasseStatsModel(
  effectif: (json['effectif'] as num).toInt(),
  seuil: (json['seuil'] as num).toDouble(),
  moyenneClasse: (json['moyenneClasse'] as num?)?.toDouble(),
  reussites: (json['reussites'] as num).toInt(),
  echecs: (json['echecs'] as num).toInt(),
  nonClasses: (json['nonClasses'] as num).toInt(),
  best: json['best'] == null
      ? null
      : ExtremeEleveModel.fromJson(json['best'] as Map<String, dynamic>),
  worst: json['worst'] == null
      ? null
      : ExtremeEleveModel.fromJson(json['worst'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ResultatsClasseStatsModelToJson(
  ResultatsClasseStatsModel instance,
) => <String, dynamic>{
  'effectif': instance.effectif,
  'seuil': instance.seuil,
  'moyenneClasse': instance.moyenneClasse,
  'reussites': instance.reussites,
  'echecs': instance.echecs,
  'nonClasses': instance.nonClasses,
  'best': instance.best?.toJson(),
  'worst': instance.worst?.toJson(),
};
