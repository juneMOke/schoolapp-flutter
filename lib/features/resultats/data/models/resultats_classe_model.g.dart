// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultats_classe_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultatsClasseModel _$ResultatsClasseModelFromJson(
  Map<String, dynamic> json,
) => ResultatsClasseModel(
  classroomId: json['classroomId'] as String,
  periodeScolaireId: json['periodeScolaireId'] as String,
  periodeOrdre: (json['periodeOrdre'] as num).toInt(),
  sousPeriodes: (json['sousPeriodes'] as List<dynamic>)
      .map((e) => SousPeriodeColonneModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  stats: ResultatsClasseStatsModel.fromJson(
    json['stats'] as Map<String, dynamic>,
  ),
  lignes: (json['lignes'] as List<dynamic>)
      .map((e) => ResultatEleveLigneModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ResultatsClasseModelToJson(
  ResultatsClasseModel instance,
) => <String, dynamic>{
  'classroomId': instance.classroomId,
  'periodeScolaireId': instance.periodeScolaireId,
  'periodeOrdre': instance.periodeOrdre,
  'sousPeriodes': instance.sousPeriodes.map((e) => e.toJson()).toList(),
  'stats': instance.stats.toJson(),
  'lignes': instance.lignes.map((e) => e.toJson()).toList(),
};
