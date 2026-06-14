import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/attendances/data/models/student_absence_entry_model.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';

part 'student_attendance_summary_model.g.dart';

@JsonSerializable(explicitToJson: true)
class StudentAttendanceSummaryModel extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String academicYearName;
  final String period;
  @JsonKey(
    fromJson: DateOnlyJsonHelper.fromJson,
    toJson: DateOnlyJsonHelper.toJson,
  )
  final DateTime windowStart;
  @JsonKey(
    fromJson: DateOnlyJsonHelper.fromJson,
    toJson: DateOnlyJsonHelper.toJson,
  )
  final DateTime windowEnd;
  final double presenceRate;
  final int presentDays;
  final int justifiedAbsenceDays;
  final int unjustifiedAbsenceDays;
  final List<StudentAbsenceEntryModel> absences;

  const StudentAttendanceSummaryModel({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.academicYearName,
    required this.period,
    required this.windowStart,
    required this.windowEnd,
    required this.presenceRate,
    required this.presentDays,
    required this.justifiedAbsenceDays,
    required this.unjustifiedAbsenceDays,
    this.absences = const [],
  });

  factory StudentAttendanceSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$StudentAttendanceSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudentAttendanceSummaryModelToJson(this);

  StudentAttendanceSummary toEntity() => StudentAttendanceSummary(
    studentId: studentId,
    firstName: firstName,
    lastName: lastName,
    academicYearName: academicYearName,
    period: StatsPeriodX.fromApiValue(period),
    windowStart: windowStart,
    windowEnd: windowEnd,
    presenceRate: presenceRate,
    presentDays: presentDays,
    justifiedAbsenceDays: justifiedAbsenceDays,
    unjustifiedAbsenceDays: unjustifiedAbsenceDays,
    absences: absences.map((a) => a.toEntity()).toList(),
  );

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    academicYearName,
    period,
    windowStart,
    windowEnd,
    presenceRate,
    presentDays,
    justifiedAbsenceDays,
    unjustifiedAbsenceDays,
    absences,
  ];
}
