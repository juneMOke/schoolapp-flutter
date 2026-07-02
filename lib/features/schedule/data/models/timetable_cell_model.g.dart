// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_cell_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimetableCellModel _$TimetableCellModelFromJson(Map<String, dynamic> json) =>
    TimetableCellModel(
      sessionId: json['sessionId'] as String,
      coursId: json['coursId'] as String,
      classroomId: json['classroomId'] as String,
      classroomLabel: json['classroomLabel'] as String,
      teacherId: json['teacherId'] as String,
      teacherLabel: json['teacherLabel'] as String,
      subjectLabel: json['subjectLabel'] as String,
      room: json['room'] as String?,
    );

Map<String, dynamic> _$TimetableCellModelToJson(TimetableCellModel instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'coursId': instance.coursId,
      'classroomId': instance.classroomId,
      'classroomLabel': instance.classroomLabel,
      'teacherId': instance.teacherId,
      'teacherLabel': instance.teacherLabel,
      'subjectLabel': instance.subjectLabel,
      'room': instance.room,
    };
