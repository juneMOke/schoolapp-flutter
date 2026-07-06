import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

/// Ligne sqflite `attendance_records` (AF-1). Stockage par exception : ne
/// matérialise que les absents (present=0) et les retards corrigés (present=1).
/// `updatedAt` (epoch ms, horloge client) arbitre le last-write-wins.
class AttendanceRecordRow extends Equatable {
  final String id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
  final String classroomId;

  /// 'yyyy-MM-dd'.
  final String attendanceDate;
  final String academicYearId;
  final bool present;
  final String? absenceReason;
  final String? absenceReasonNote;
  final int? version;
  final int updatedAt;
  final String syncStatus;
  final int? syncedAt;

  const AttendanceRecordRow({
    required this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.classroomId,
    required this.attendanceDate,
    required this.academicYearId,
    required this.present,
    this.absenceReason,
    this.absenceReasonNote,
    this.version,
    required this.updatedAt,
    this.syncStatus = 'PENDING_SYNC',
    this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory AttendanceRecordRow.fromMap(Map<String, Object?> map) =>
      AttendanceRecordRow(
        id: map['id'] as String,
        studentId: map['student_id'] as String,
        studentFirstName: map['student_first_name'] as String,
        studentLastName: map['student_last_name'] as String,
        studentMiddleName: map['student_middle_name'] as String?,
        studentGender: (map['student_gender'] as String?) ?? 'OTHER',
        classroomId: map['classroom_id'] as String,
        attendanceDate: map['attendance_date'] as String,
        academicYearId: map['academic_year_id'] as String,
        present: ((map['present'] as int?) ?? 1) == 1,
        absenceReason: map['absence_reason'] as String?,
        absenceReasonNote: map['absence_reason_note'] as String?,
        version: _asIntOrNull(map['version']),
        updatedAt: _asIntOrNull(map['updated_at']) ?? 0,
        syncStatus: (map['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncedAt: _asIntOrNull(map['synced_at']),
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'student_id': studentId,
    'student_first_name': studentFirstName,
    'student_last_name': studentLastName,
    'student_middle_name': studentMiddleName,
    'student_gender': studentGender,
    'classroom_id': classroomId,
    'attendance_date': attendanceDate,
    'academic_year_id': academicYearId,
    'present': present ? 1 : 0,
    'absence_reason': absenceReason,
    'absence_reason_note': absenceReasonNote,
    'version': version,
    'updated_at': updatedAt,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
  };

  AttendanceRecord toEntity() => AttendanceRecord(
    id: id,
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: StudentGenderX.fromApiValue(studentGender),
    classroomId: classroomId,
    academicYearId: academicYearId,
    attendanceDate: DateOnlyJsonHelper.fromJson(attendanceDate),
    present: present,
    absenceReason: AbsenceReasonX.fromApiValue(absenceReason),
    absenceReasonNote: absenceReasonNote,
  );

  bool get isSynced => SyncState.fromDbValue(syncStatus).isSynced;

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    classroomId,
    attendanceDate,
    academicYearId,
    present,
    absenceReason,
    absenceReasonNote,
    version,
    updatedAt,
    syncStatus,
    syncedAt,
  ];
}
