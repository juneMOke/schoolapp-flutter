// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_disciplinary_case_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateDisciplinaryCaseRequestModel _$CreateDisciplinaryCaseRequestModelFromJson(
  Map<String, dynamic> json,
) => CreateDisciplinaryCaseRequestModel(
  studentId: json['studentId'] as String,
  studentFirstName: json['studentFirstName'] as String,
  studentLastName: json['studentLastName'] as String,
  studentMiddleName: json['studentMiddleName'] as String?,
  studentGender: json['studentGender'] as String,
  disciplinaryCaseDate: DateOnlyJsonHelper.fromJson(
    json['disciplinaryCaseDate'] as String,
  ),
  academicYearId: json['academicYearId'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
);

Map<String, dynamic> _$CreateDisciplinaryCaseRequestModelToJson(
  CreateDisciplinaryCaseRequestModel instance,
) => <String, dynamic>{
  'studentId': instance.studentId,
  'studentFirstName': instance.studentFirstName,
  'studentLastName': instance.studentLastName,
  'studentMiddleName': instance.studentMiddleName,
  'studentGender': instance.studentGender,
  'disciplinaryCaseDate': DateOnlyJsonHelper.toJson(
    instance.disciplinaryCaseDate,
  ),
  'academicYearId': instance.academicYearId,
  'title': instance.title,
  'content': instance.content,
};
