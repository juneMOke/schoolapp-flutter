// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sous_periode_notation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SousPeriodeNotationModel _$SousPeriodeNotationModelFromJson(
  Map<String, dynamic> json,
) => SousPeriodeNotationModel(
  sousPeriodeId: json['sousPeriodeId'] as String,
  ordre: (json['ordre'] as num).toInt(),
  statut: json['statut'] as String,
  moyenneClasse: (json['moyenneClasse'] as num?)?.toDouble(),
  nombreElevesNotes: (json['nombreElevesNotes'] as num).toInt(),
  nombreEleves50: (json['nombreEleves50'] as num).toInt(),
  moyennesEleves: (json['moyennesEleves'] as List<dynamic>)
      .map((e) => MoyenneEleveModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  evaluationsParType: (json['evaluationsParType'] as List<dynamic>)
      .map((e) => EvaluationGroupeModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SousPeriodeNotationModelToJson(
  SousPeriodeNotationModel instance,
) => <String, dynamic>{
  'sousPeriodeId': instance.sousPeriodeId,
  'ordre': instance.ordre,
  'statut': instance.statut,
  'moyenneClasse': instance.moyenneClasse,
  'nombreElevesNotes': instance.nombreElevesNotes,
  'nombreEleves50': instance.nombreEleves50,
  'moyennesEleves': instance.moyennesEleves.map((e) => e.toJson()).toList(),
  'evaluationsParType': instance.evaluationsParType
      .map((e) => e.toJson())
      .toList(),
};
