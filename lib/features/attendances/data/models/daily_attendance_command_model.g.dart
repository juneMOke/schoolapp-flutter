// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_attendance_command_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyAttendanceCommandModel _$DailyAttendanceCommandModelFromJson(
  Map<String, dynamic> json,
) => DailyAttendanceCommandModel(
  classroomId: json['classroomId'] as String,
  date: DateOnlyJsonHelper.fromJson(json['date'] as String),
  academicYearId: json['academicYearId'] as String,
  updates: (json['updates'] as List<dynamic>)
      .map((e) => AttendanceUpdateModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DailyAttendanceCommandModelToJson(
  DailyAttendanceCommandModel instance,
) => <String, dynamic>{
  'classroomId': instance.classroomId,
  'date': DateOnlyJsonHelper.toJson(instance.date),
  'academicYearId': instance.academicYearId,
  'updates': instance.updates.map((e) => e.toJson()).toList(),
};
