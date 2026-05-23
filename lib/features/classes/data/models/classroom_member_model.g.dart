// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassroomMemberModel _$ClassroomMemberModelFromJson(
  Map<String, dynamic> json,
) => ClassroomMemberModel(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  classroomId: json['classroomId'] as String,
  academicYearId: json['academicYearId'] as String,
  studentFirstName: json['studentFirstName'] as String,
  studentLastName: json['studentLastName'] as String,
  studentMiddleName: json['studentMiddleName'] as String?,
  studentGender: json['studentGender'] as String,
);

Map<String, dynamic> _$ClassroomMemberModelToJson(
  ClassroomMemberModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'studentId': instance.studentId,
  'classroomId': instance.classroomId,
  'academicYearId': instance.academicYearId,
  'studentFirstName': instance.studentFirstName,
  'studentLastName': instance.studentLastName,
  'studentMiddleName': instance.studentMiddleName,
  'studentGender': instance.studentGender,
};
