// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulletin_domaine_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulletinDomaineModel _$BulletinDomaineModelFromJson(
  Map<String, dynamic> json,
) => BulletinDomaineModel(
  domaines: (json['domaines'] as List<dynamic>)
      .map((e) => DomaineResultatModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalObtenu: (json['totalObtenu'] as num).toDouble(),
  totalMax: (json['totalMax'] as num).toDouble(),
  pourcentage: (json['pourcentage'] as num).toDouble(),
);

Map<String, dynamic> _$BulletinDomaineModelToJson(
  BulletinDomaineModel instance,
) => <String, dynamic>{
  'domaines': instance.domaines.map((e) => e.toJson()).toList(),
  'totalObtenu': instance.totalObtenu,
  'totalMax': instance.totalMax,
  'pourcentage': instance.pourcentage,
};
