import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_update_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';

part 'daily_attendance_command_model.g.dart';

DateTime _dateOnlyFromJson(String value) => DateTime.parse(value);

String _dateOnlyToJson(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

@JsonSerializable(explicitToJson: true)
class DailyAttendanceCommandModel extends Equatable {
  final String classroomId;
  @JsonKey(fromJson: _dateOnlyFromJson, toJson: _dateOnlyToJson)
  final DateTime date;
  final String academicYearId;
  final List<AttendanceUpdateModel> updates;

  const DailyAttendanceCommandModel({
    required this.classroomId,
    required this.date,
    required this.academicYearId,
    required this.updates,
  });

  factory DailyAttendanceCommandModel.fromDomain({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
    required List<AttendanceUpdate> updates,
  }) => DailyAttendanceCommandModel(
    classroomId: classroomId,
    date: date,
    academicYearId: academicYearId,
    updates: updates.map(AttendanceUpdateModel.fromEntity).toList(),
  );

  factory DailyAttendanceCommandModel.fromJson(Map<String, dynamic> json) =>
      _$DailyAttendanceCommandModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyAttendanceCommandModelToJson(this);

  @override
  List<Object?> get props => [classroomId, date, academicYearId, updates];
}
