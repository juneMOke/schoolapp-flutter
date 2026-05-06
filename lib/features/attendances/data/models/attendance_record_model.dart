import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

part 'attendance_record_model.g.dart';

@JsonSerializable()
class AttendanceRecordModel extends Equatable {
  final String? id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
  final String classroomId;
  final String academicYearId;
  @JsonKey(fromJson: DateOnlyJsonHelper.fromJson, toJson: DateOnlyJsonHelper.toJson)
  final DateTime attendanceDate;
  final bool present;
  final String? absenceReason;
  final String? absenceReasonNote;

  const AttendanceRecordModel({
    this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.classroomId,
    required this.academicYearId,
    required this.attendanceDate,
    required this.present,
    this.absenceReason,
    this.absenceReasonNote,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceRecordModelToJson(this);

  AttendanceRecord toEntity() => AttendanceRecord(
    id: id,
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: StudentGenderX.fromApiValue(studentGender),
    classroomId: classroomId,
    academicYearId: academicYearId,
    attendanceDate: attendanceDate,
    present: present,
    absenceReason: AbsenceReasonX.fromApiValue(absenceReason),
    absenceReasonNote: absenceReasonNote,
  );

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    classroomId,
    academicYearId,
    attendanceDate,
    present,
    absenceReason,
    absenceReasonNote,
  ];
}
