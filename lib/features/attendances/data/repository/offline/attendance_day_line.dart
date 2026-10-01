import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';

/// Une exception de l'appel à écrire : un retard ou une absence.
class AttendanceDayLine extends Equatable {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;

  /// Genre sur le fil (`MALE`, `FEMALE`, `OTHER`).
  final String studentGender;

  /// [PresenceStatus.late] ou [PresenceStatus.absent].
  final PresenceStatus status;

  /// `HH:mm`, retard seulement.
  final String? arrivalTime;
  final int? lateMinutes;

  /// Motif codé (`SICKNESS`…), `null` = non justifiée.
  final String? absenceReason;
  final String? absenceReasonNote;

  const AttendanceDayLine({
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    required this.studentGender,
    required this.status,
    this.studentMiddleName,
    this.arrivalTime,
    this.lateMinutes,
    this.absenceReason,
    this.absenceReasonNote,
  });

  bool get _isLate => status == PresenceStatus.late;

  /// La ligne en base dit-elle déjà la même chose ? Une ligne inchangée garde
  /// son horodatage : la réestamper lui ferait gagner un arbitrage LWW qu'elle
  /// ne doit pas gagner.
  bool sameAs(AttendanceRecordRow row) =>
      row.presenceStatus == status &&
      row.arrivalTime == (_isLate ? arrivalTime : null) &&
      row.lateMinutes == (_isLate ? lateMinutes : null) &&
      row.absenceReason == absenceReason &&
      row.absenceReasonNote == absenceReasonNote;

  @override
  List<Object?> get props => [
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    status,
    arrivalTime,
    lateMinutes,
    absenceReason,
    absenceReasonNote,
  ];
}
