// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branche_resultat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrancheResultatModel _$BrancheResultatModelFromJson(
  Map<String, dynamic> json,
) => BrancheResultatModel(
  ligneBaremeId: json['ligneBaremeId'] as String,
  brancheId: json['brancheId'] as String,
  brancheNom: json['brancheNom'] as String,
  obtenu: (json['obtenu'] as num).toDouble(),
  max: (json['max'] as num).toDouble(),
  pourcentage: (json['pourcentage'] as num?)?.toDouble(),
);

Map<String, dynamic> _$BrancheResultatModelToJson(
  BrancheResultatModel instance,
) => <String, dynamic>{
  'ligneBaremeId': instance.ligneBaremeId,
  'brancheId': instance.brancheId,
  'brancheNom': instance.brancheNom,
  'obtenu': instance.obtenu,
  'max': instance.max,
  'pourcentage': instance.pourcentage,
};
