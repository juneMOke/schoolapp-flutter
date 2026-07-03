// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sous_periode_colonne_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SousPeriodeColonneModel _$SousPeriodeColonneModelFromJson(
  Map<String, dynamic> json,
) => SousPeriodeColonneModel(
  sousPeriodeId: json['sousPeriodeId'] as String,
  ordre: (json['ordre'] as num).toInt(),
  statut: json['statut'] as String,
);

Map<String, dynamic> _$SousPeriodeColonneModelToJson(
  SousPeriodeColonneModel instance,
) => <String, dynamic>{
  'sousPeriodeId': instance.sousPeriodeId,
  'ordre': instance.ordre,
  'statut': instance.statut,
};
