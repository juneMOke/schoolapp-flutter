// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) => SessionModel(
  id: json['id'] as String,
  academicYearId: json['academicYearId'] as String,
  coursId: json['coursId'] as String,
  timeSlotId: json['timeSlotId'] as String,
  day: json['day'] as String,
  room: json['room'] as String?,
  teacherId: json['teacherId'] as String,
  classroomId: json['classroomId'] as String,
  teacherLabel: json['teacherLabel'] as String,
  classroomLabel: json['classroomLabel'] as String,
  subjectLabel: json['subjectLabel'] as String,
);

Map<String, dynamic> _$SessionModelToJson(SessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'academicYearId': instance.academicYearId,
      'coursId': instance.coursId,
      'timeSlotId': instance.timeSlotId,
      'day': instance.day,
      'room': instance.room,
      'teacherId': instance.teacherId,
      'classroomId': instance.classroomId,
      'teacherLabel': instance.teacherLabel,
      'classroomLabel': instance.classroomLabel,
      'subjectLabel': instance.subjectLabel,
    };
