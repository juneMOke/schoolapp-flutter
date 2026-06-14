// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_attendance_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentAttendanceSummaryModel _$StudentAttendanceSummaryModelFromJson(
  Map<String, dynamic> json,
) => StudentAttendanceSummaryModel(
  studentId: json['studentId'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  academicYearName: json['academicYearName'] as String,
  period: json['period'] as String,
  windowStart: DateOnlyJsonHelper.fromJson(json['windowStart'] as String),
  windowEnd: DateOnlyJsonHelper.fromJson(json['windowEnd'] as String),
  presenceRate: (json['presenceRate'] as num).toDouble(),
  presentDays: (json['presentDays'] as num).toInt(),
  justifiedAbsenceDays: (json['justifiedAbsenceDays'] as num).toInt(),
  unjustifiedAbsenceDays: (json['unjustifiedAbsenceDays'] as num).toInt(),
  absences:
      (json['absences'] as List<dynamic>?)
          ?.map(
            (e) => StudentAbsenceEntryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$StudentAttendanceSummaryModelToJson(
  StudentAttendanceSummaryModel instance,
) => <String, dynamic>{
  'studentId': instance.studentId,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'academicYearName': instance.academicYearName,
  'period': instance.period,
  'windowStart': DateOnlyJsonHelper.toJson(instance.windowStart),
  'windowEnd': DateOnlyJsonHelper.toJson(instance.windowEnd),
  'presenceRate': instance.presenceRate,
  'presentDays': instance.presentDays,
  'justifiedAbsenceDays': instance.justifiedAbsenceDays,
  'unjustifiedAbsenceDays': instance.unjustifiedAbsenceDays,
  'absences': instance.absences.map((e) => e.toJson()).toList(),
};
