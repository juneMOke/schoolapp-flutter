// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domaine_resultat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomaineResultatModel _$DomaineResultatModelFromJson(
  Map<String, dynamic> json,
) => DomaineResultatModel(
  rubriqueId: json['rubriqueId'] as String,
  label: json['label'] as String?,
  produitSousTotal: json['produitSousTotal'] as bool,
  obtenu: (json['obtenu'] as num).toDouble(),
  max: (json['max'] as num).toDouble(),
  pourcentage: (json['pourcentage'] as num?)?.toDouble(),
  sousRubriques:
      (json['sousRubriques'] as List<dynamic>?)
          ?.map((e) => DomaineResultatModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  branches:
      (json['branches'] as List<dynamic>?)
          ?.map((e) => BrancheResultatModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DomaineResultatModelToJson(
  DomaineResultatModel instance,
) => <String, dynamic>{
  'rubriqueId': instance.rubriqueId,
  'label': instance.label,
  'produitSousTotal': instance.produitSousTotal,
  'obtenu': instance.obtenu,
  'max': instance.max,
  'pourcentage': instance.pourcentage,
  'sousRubriques': instance.sousRubriques.map((e) => e.toJson()).toList(),
  'branches': instance.branches.map((e) => e.toJson()).toList(),
};
