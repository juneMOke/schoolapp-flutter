import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Ligne `attendance_draft_marks` : la marque d'un élève dans l'appel en cours
/// de saisie (jamais envoyée).
class AttendanceDraftMarkRow extends Equatable {
  final String classroomId;

  /// `YYYY-MM-DD`.
  final String attendanceDate;
  final String academicYearId;
  final String studentId;

  /// `PRESENT`, `LATE`, `ABSENT` ou — sur un appel rouvert seulement —
  /// `NONE`, un élève remis « à pointer » ([statusWire]).
  final String status;

  /// `HH:mm` (présent ou retard).
  final String? arrivalTime;
  final int? lateMinutes;
  final String? absenceReason;
  final String? absenceReasonNote;
  final int updatedAt;

  const AttendanceDraftMarkRow({
    required this.classroomId,
    required this.attendanceDate,
    required this.academicYearId,
    required this.studentId,
    required this.status,
    required this.updatedAt,
    this.arrivalTime,
    this.lateMinutes,
    this.absenceReason,
    this.absenceReasonNote,
  });

  static String statusWire(PresenceStatus status) => switch (status) {
    PresenceStatus.present => 'PRESENT',
    PresenceStatus.late => 'LATE',
    PresenceStatus.absent => 'ABSENT',
    PresenceStatus.none => 'NONE',
  };

  /// Une valeur inconnue se lit « à pointer » : le brouillon est local, rien
  /// ne doit y tromper l'appel.
  PresenceStatus get presenceStatus => switch (status) {
    'PRESENT' => PresenceStatus.present,
    'LATE' => PresenceStatus.late,
    'ABSENT' => PresenceStatus.absent,
    _ => PresenceStatus.none,
  };

  factory AttendanceDraftMarkRow.fromMap(Map<String, Object?> map) =>
      AttendanceDraftMarkRow(
        classroomId: map['classroom_id']! as String,
        attendanceDate: map['attendance_date']! as String,
        academicYearId: map['academic_year_id']! as String,
        studentId: map['student_id']! as String,
        status: map['status']! as String,
        arrivalTime: map['arrival_time'] as String?,
        lateMinutes: (map['late_minutes'] as num?)?.toInt(),
        absenceReason: map['absence_reason'] as String?,
        absenceReasonNote: map['absence_reason_note'] as String?,
        updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toMap() => {
    'classroom_id': classroomId,
    'attendance_date': attendanceDate,
    'academic_year_id': academicYearId,
    'student_id': studentId,
    'status': status,
    'arrival_time': arrivalTime,
    'late_minutes': lateMinutes,
    'absence_reason': absenceReason,
    'absence_reason_note': absenceReasonNote,
    'updated_at': updatedAt,
  };

  @override
  List<Object?> get props => [
    classroomId,
    attendanceDate,
    academicYearId,
    studentId,
    status,
    arrivalTime,
    lateMinutes,
    absenceReason,
    absenceReasonNote,
    updatedAt,
  ];
}
