// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moyenne_eleve_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoyenneEleveModel _$MoyenneEleveModelFromJson(Map<String, dynamic> json) =>
    MoyenneEleveModel(
      studentId: json['studentId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      middleName: json['middleName'] as String?,
      moyenne: (json['moyenne'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MoyenneEleveModelToJson(MoyenneEleveModel instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'middleName': instance.middleName,
      'moyenne': instance.moyenne,
    };
