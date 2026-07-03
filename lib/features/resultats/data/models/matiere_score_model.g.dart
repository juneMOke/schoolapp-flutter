// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matiere_score_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatiereScoreModel _$MatiereScoreModelFromJson(Map<String, dynamic> json) =>
    MatiereScoreModel(
      brancheId: json['brancheId'] as String,
      brancheNom: json['brancheNom'] as String,
      pourcentage: (json['pourcentage'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MatiereScoreModelToJson(MatiereScoreModel instance) =>
    <String, dynamic>{
      'brancheId': instance.brancheId,
      'brancheNom': instance.brancheNom,
      'pourcentage': instance.pourcentage,
    };
