// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_update_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceUpdateModel _$AttendanceUpdateModelFromJson(
  Map<String, dynamic> json,
) => AttendanceUpdateModel(
  studentId: json['studentId'] as String,
  studentFirstName: json['studentFirstName'] as String,
  studentLastName: json['studentLastName'] as String,
  studentMiddleName: json['studentMiddleName'] as String?,
  studentGender: json['studentGender'] as String,
  present: json['present'] as bool,
  absenceReason: json['absenceReason'] as String?,
  absenceReasonNote: json['absenceReasonNote'] as String?,
);

Map<String, dynamic> _$AttendanceUpdateModelToJson(
  AttendanceUpdateModel instance,
) => <String, dynamic>{
  'studentId': instance.studentId,
  'studentFirstName': instance.studentFirstName,
  'studentLastName': instance.studentLastName,
  'studentMiddleName': instance.studentMiddleName,
  'studentGender': instance.studentGender,
  'present': instance.present,
  'absenceReason': instance.absenceReason,
  'absenceReasonNote': instance.absenceReasonNote,
};
