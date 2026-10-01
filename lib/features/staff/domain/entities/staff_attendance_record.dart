import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// La justification d'un retard ou d'une absence d'un agent.
typedef StaffAttendanceJustification =
    PresenceJustification<StaffAbsenceReason>;

/// Le pointage d'un agent pour un jour — une seule ligne par agent et par
/// jour, d'identifiant déterministe (voir `StaffAttendanceIds`).
class StaffAttendanceRecord extends Equatable {
  final String id;
  final String staffMemberId;

  /// Jour `YYYY-MM-DD`, la date civile de l'école.
  final String workDate;

  final PresenceStatus status;
  final ClockTime? arrival;
  final ClockTime? departure;

  /// Minutes comptées depuis le début des cours ; 0 hors retard.
  final int lateMinutes;

  /// Heures prestées d'un vacataire payé à l'heure, en minutes (0 à 600).
  final int? workedMinutes;

  final StaffAttendanceJustification? justification;

  final RecordSyncState syncState;

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
    this.syncState = RecordSyncState.synced,
    this.syncErrorCode,
  });

  /// Heures prestées maximales : 10 h.
  static const int maxWorkedMinutes = 600;

  /// Ce qui est pointé, sans l'agent ni le jour : la forme que corrige
  /// l'éditeur commun.
  PresenceMark<StaffAbsenceReason> get mark => PresenceMark(
    status: status,
    arrival: arrival,
    departure: departure,
    lateMinutes: lateMinutes,
    justification: justification,
  );

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
