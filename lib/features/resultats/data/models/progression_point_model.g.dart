// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progression_point_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgressionPointModel _$ProgressionPointModelFromJson(
  Map<String, dynamic> json,
) => ProgressionPointModel(
  sousPeriodeId: json['sousPeriodeId'] as String,
  indexGlobal: (json['indexGlobal'] as num).toInt(),
  periodeOrdre: (json['periodeOrdre'] as num).toInt(),
  sousPeriodeOrdre: (json['sousPeriodeOrdre'] as num).toInt(),
  pourcentage: (json['pourcentage'] as num?)?.toDouble(),
  statut: json['statut'] as String,
  dansGroupe: json['dansGroupe'] as bool,
);

Map<String, dynamic> _$ProgressionPointModelToJson(
  ProgressionPointModel instance,
) => <String, dynamic>{
  'sousPeriodeId': instance.sousPeriodeId,
  'indexGlobal': instance.indexGlobal,
  'periodeOrdre': instance.periodeOrdre,
  'sousPeriodeOrdre': instance.sousPeriodeOrdre,
  'pourcentage': instance.pourcentage,
  'statut': instance.statut,
  'dansGroupe': instance.dansGroupe,
};
