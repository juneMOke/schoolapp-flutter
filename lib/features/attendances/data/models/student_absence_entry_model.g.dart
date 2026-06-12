// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_absence_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentAbsenceEntryModel _$StudentAbsenceEntryModelFromJson(
  Map<String, dynamic> json,
) => StudentAbsenceEntryModel(
  date: DateOnlyJsonHelper.fromJson(json['date'] as String),
  reason: json['reason'] as String?,
  reasonNote: json['reasonNote'] as String?,
);

Map<String, dynamic> _$StudentAbsenceEntryModelToJson(
  StudentAbsenceEntryModel instance,
) => <String, dynamic>{
  'date': DateOnlyJsonHelper.toJson(instance.date),
  'reason': instance.reason,
  'reasonNote': instance.reasonNote,
};
