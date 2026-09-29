import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// La justification d'un retard ou d'une absence. La pièce jointe est
/// reportée en V1.1 : motif et précision seulement.
class StaffAttendanceJustification extends Equatable {
  final StaffAbsenceReason reason;

  /// Précision libre, au plus [maxNoteLength] caractères.
  final String? note;

  const StaffAttendanceJustification({required this.reason, this.note});

  static const int maxNoteLength = 500;

  @override
  List<Object?> get props => [reason, note];
}

/// Le pointage d'un agent pour un jour — une seule ligne par agent et par
/// jour, d'identifiant déterministe (voir `StaffAttendanceIds`).
class StaffAttendanceRecord extends Equatable {
  final String id;
  final String staffMemberId;

  /// Jour `YYYY-MM-DD`, la date civile de l'école.
  final String workDate;

  final StaffAttendanceStatus status;
  final StaffClockTime? arrival;
  final StaffClockTime? departure;

  /// Minutes comptées depuis le début des cours ; 0 hors retard.
  final int lateMinutes;

  /// Heures prestées d'un vacataire payé à l'heure, en minutes (0 à 600).
  final int? workedMinutes;

  final StaffAttendanceJustification? justification;

  final StaffSyncState syncState;

  /// Code du dernier refus (`DAY_LOCKED`, `MONTH_CLOSED`…), `null` sinon.
  final String? syncErrorCode;

  const StaffAttendanceRecord({
    required this.id,
    required this.staffMemberId,
    required this.workDate,
    required this.status,
    this.arrival,
    this.departure,
    this.lateMinutes = 0,
    this.workedMinutes,
    this.justification,
    this.syncState = StaffSyncState.synced,
    this.syncErrorCode,
  });

  /// Heures prestées maximales : 10 h.
  static const int maxWorkedMinutes = 600;

  bool get isJustified => justification != null;

  /// Un retard ou une absence sans justification.
  bool get needsJustification => status.isIncident && !isJustified;

  @override
  List<Object?> get props => [
    id,
    staffMemberId,
    workDate,
    status,
    arrival,
    departure,
    lateMinutes,
    workedMinutes,
    justification,
    syncState,
    syncErrorCode,
  ];
}
