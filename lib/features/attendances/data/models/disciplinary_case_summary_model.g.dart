// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disciplinary_case_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplinaryCaseSummaryModel _$DisciplinaryCaseSummaryModelFromJson(
  Map<String, dynamic> json,
) => DisciplinaryCaseSummaryModel(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  studentFirstName: json['studentFirstName'] as String,
  studentLastName: json['studentLastName'] as String,
  studentMiddleName: json['studentMiddleName'] as String?,
  studentGender: json['studentGender'] as String,
  academicYearId: json['academicYearId'] as String,
  title: json['title'] as String,
  status: json['status'] as String,
  content: json['content'] as String,
);

Map<String, dynamic> _$DisciplinaryCaseSummaryModelToJson(
  DisciplinaryCaseSummaryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'studentFirstName': instance.studentFirstName,
  'studentLastName': instance.studentLastName,
  'studentMiddleName': instance.studentMiddleName,
  'studentGender': instance.studentGender,
  'academicYearId': instance.academicYearId,
  'title': instance.title,
  'status': instance.status,
  'content': instance.content,
};
