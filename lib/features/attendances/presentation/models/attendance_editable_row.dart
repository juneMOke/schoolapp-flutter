import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

class AttendanceEditableRow extends Equatable {
  final String? id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final StudentGender studentGender;
  final bool present;
  final AbsenceReason? absenceReason;
  final String absenceReasonNote;

  const AttendanceEditableRow({
    this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.present,
    required this.absenceReason,
    required this.absenceReasonNote,
  });

  factory AttendanceEditableRow.fromRecord(AttendanceRecord record) =>
      AttendanceEditableRow(
        id: record.id,
        studentId: record.studentId,
        studentFirstName: record.studentFirstName,
        studentLastName: record.studentLastName,
        studentMiddleName: record.studentMiddleName,
        studentGender: record.studentGender,
        present: record.present,
        absenceReason: record.present ? null : record.absenceReason,
        absenceReasonNote: record.present ? '' : (record.absenceReasonNote ?? ''),
      );

  AttendanceEditableRow copyWith({
    bool? present,
    Object? absenceReason = _undefined,
    String? absenceReasonNote,
  }) => AttendanceEditableRow(
    id: id,
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: studentGender,
    present: present ?? this.present,
    absenceReason: identical(absenceReason, _undefined)
        ? this.absenceReason
        : absenceReason as AbsenceReason?,
    absenceReasonNote: absenceReasonNote ?? this.absenceReasonNote,
  );

  AttendanceUpdate toUpdate() => AttendanceUpdate(
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: studentGender,
    present: present,
    absenceReason: present ? null : absenceReason,
    absenceReasonNote: present
        ? null
        : absenceReasonNote.trim().isEmpty
            ? null
            : absenceReasonNote.trim(),
  );

  bool get requiresAbsenceReason => !present;

  bool get hasValidationError => requiresAbsenceReason && absenceReason == null;

  @override
  List<Object?> get props => [
    id,
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

const _undefined = Object();
