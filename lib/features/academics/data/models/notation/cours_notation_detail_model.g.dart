// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cours_notation_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoursNotationDetailModel _$CoursNotationDetailModelFromJson(
  Map<String, dynamic> json,
) => CoursNotationDetailModel(
  coursId: json['coursId'] as String,
  classroomId: json['classroomId'] as String,
  brancheNom: json['brancheNom'] as String?,
  effectif: (json['effectif'] as num).toInt(),
  periodes: (json['periodes'] as List<dynamic>)
      .map((e) => PeriodeNotationModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CoursNotationDetailModelToJson(
  CoursNotationDetailModel instance,
) => <String, dynamic>{
  'coursId': instance.coursId,
  'classroomId': instance.classroomId,
  'brancheNom': instance.brancheNom,
  'effectif': instance.effectif,
  'periodes': instance.periodes.map((e) => e.toJson()).toList(),
};
