import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

part 'attendance_update_model.g.dart';

@JsonSerializable()
class AttendanceUpdateModel extends Equatable {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
  final bool present;
  final String? absenceReason;
  final String? absenceReasonNote;

  const AttendanceUpdateModel({
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.present,
    this.absenceReason,
    this.absenceReasonNote,
  });

  factory AttendanceUpdateModel.fromEntity(AttendanceUpdate update) =>
      AttendanceUpdateModel(
        studentId: update.studentId,
        studentFirstName: update.studentFirstName,
        studentLastName: update.studentLastName,
        studentMiddleName: update.studentMiddleName,
        studentGender: update.studentGender.toApiValue(),
        present: update.present,
        absenceReason: update.absenceReason?.toApiValue(),
        absenceReasonNote: update.absenceReasonNote,
      );

  factory AttendanceUpdateModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceUpdateModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceUpdateModelToJson(this);

  @override
  List<Object?> get props => [
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    present,
    absenceReason,
    absenceReasonNote,
  ];
}
