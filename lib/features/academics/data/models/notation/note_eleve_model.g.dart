// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_eleve_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteEleveModel _$NoteEleveModelFromJson(Map<String, dynamic> json) =>
    NoteEleveModel(
      studentId: json['studentId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      middleName: json['middleName'] as String?,
      pointsObtenus: (json['pointsObtenus'] as num?)?.toDouble(),
      statut: json['statut'] as String?,
    );

Map<String, dynamic> _$NoteEleveModelToJson(NoteEleveModel instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'middleName': instance.middleName,
      'pointsObtenus': instance.pointsObtenus,
      'statut': instance.statut,
    };
