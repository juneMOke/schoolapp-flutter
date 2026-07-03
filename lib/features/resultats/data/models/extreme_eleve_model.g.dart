// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extreme_eleve_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtremeEleveModel _$ExtremeEleveModelFromJson(Map<String, dynamic> json) =>
    ExtremeEleveModel(
      studentId: json['studentId'] as String,
      nomComplet: json['nomComplet'] as String,
      pourcentage: (json['pourcentage'] as num).toDouble(),
    );

Map<String, dynamic> _$ExtremeEleveModelToJson(ExtremeEleveModel instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'nomComplet': instance.nomComplet,
      'pourcentage': instance.pourcentage,
    };
