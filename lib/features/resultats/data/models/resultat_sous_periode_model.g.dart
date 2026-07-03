// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_sous_periode_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultatSousPeriodeModel _$ResultatSousPeriodeModelFromJson(
  Map<String, dynamic> json,
) => ResultatSousPeriodeModel(
  sousPeriodeId: json['sousPeriodeId'] as String,
  pourcentage: (json['pourcentage'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ResultatSousPeriodeModelToJson(
  ResultatSousPeriodeModel instance,
) => <String, dynamic>{
  'sousPeriodeId': instance.sousPeriodeId,
  'pourcentage': instance.pourcentage,
};
