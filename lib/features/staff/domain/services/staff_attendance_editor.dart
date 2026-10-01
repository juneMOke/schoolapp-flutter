import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark_editor.dart';
import 'package:school_app_flutter/core/presence/domain/presence_rules.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_attendance_ids.dart';

/// Les modifications d'un pointage d'agent : la cohérence du statut, des
/// heures et de la justification est celle de l'éditeur commun
/// ([PresenceMarkEditor]) ; ce qui reste propre au Pointage, ce sont les
/// heures prestées d'un vacataire, gardées tant que le statut garde une
/// arrivée.
///
/// Calcul pur : l'écriture et la mise en file sont l'affaire du dépôt.
class StaffAttendanceEditor {
  final PresenceMarkEditor _marks;

  StaffAttendanceEditor(PresenceRules rules)
    : _marks = PresenceMarkEditor(rules);

  /// La ligne vierge d'un agent pour un jour, « à pointer ».
  static StaffAttendanceRecord blank({
    required String staffMemberId,
    required String workDate,
  }) => StaffAttendanceRecord(
    id: StaffAttendanceIds.recordId(
      staffMemberId: staffMemberId,
      workDate: workDate,
    ),
    staffMemberId: staffMemberId,
    workDate: workDate,
    status: PresenceStatus.none,
    syncState: RecordSyncState.pending,
  );

  StaffAttendanceRecord mark(
    StaffAttendanceRecord record,
    PresenceStatus status,
    ClockTime now,
  ) => _apply(record, _marks.mark(record.mark, status, now));

  StaffAttendanceRecord setArrival(
    StaffAttendanceRecord record,
    ClockTime arrival,
  ) => _apply(record, _marks.setArrival(record.mark, arrival));

  /// Saisit ou efface le départ. Sans arrivée, ou avant l'arrivée, rien ne
  /// change ; sinon la ligne repart, même au même départ — ressaisir le
  /// départ d'une ligne refusée la renvoie, comme avant le socle commun.
  StaffAttendanceRecord setDeparture(
    StaffAttendanceRecord record,
    ClockTime? departure,
  ) {
    final arrival = record.arrival;
    if (!record.status.hasArrival || arrival == null) return record;
    if (departure != null && departure.compareTo(arrival) < 0) return record;
    return _apply(record, _marks.setDeparture(record.mark, departure));
  }

  /// Heures prestées d'un vacataire payé à l'heure, bornées à 0–10 h.
  StaffAttendanceRecord setWorked(StaffAttendanceRecord record, int minutes) {
    if (!record.status.hasArrival) return record;
    return _apply(
      record,
      record.mark,
      workedMinutes: minutes.clamp(0, StaffAttendanceRecord.maxWorkedMinutes),
    );
  }

  StaffAttendanceRecord justify(
    StaffAttendanceRecord record,
    StaffAttendanceJustification? justification,
  ) {
    if (!record.status.isIncident) return record;
    return _apply(record, _marks.justify(record.mark, justification));
  }

  StaffAttendanceRecord clear(StaffAttendanceRecord record) =>
      _apply(record, _marks.clear(record.mark));

  /// La ligne de [record] portant [mark], à envoyer. Les heures prestées
  /// suivent l'arrivée : un statut sans arrivée les efface.
  static StaffAttendanceRecord _apply(
    StaffAttendanceRecord record,
    PresenceMark<StaffAbsenceReason> mark, {
    int? workedMinutes,
  }) => StaffAttendanceRecord(
    id: record.id,
    staffMemberId: record.staffMemberId,
    workDate: record.workDate,
    status: mark.status,
    arrival: mark.arrival,
    departure: mark.departure,
    lateMinutes: mark.lateMinutes,
    workedMinutes: mark.status.hasArrival
        ? workedMinutes ?? record.workedMinutes
        : null,
    justification: mark.justification,
    syncState: RecordSyncState.pending,
  );
}
