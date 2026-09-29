import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_attendance_ids.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_attendance_rules.dart';

/// Les modifications d'un pointage, chacune rendant une ligne **cohérente**
/// au sens du serveur :
/// - à pointer : tout à vide ;
/// - présent : arrivée, retard 0, pas de justification ;
/// - en retard : arrivée, retard > 0 ;
/// - absent : ni arrivée, ni départ, ni heures.
///
/// Calcul pur : l'écriture et la mise en file sont l'affaire du dépôt.
class StaffAttendanceEditor {
  final StaffAttendanceRules rules;

  const StaffAttendanceEditor(this.rules);

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
    status: StaffAttendanceStatus.none,
    syncState: StaffSyncState.pending,
  );

  /// Pose [status] avec l'heure proposée ; garde le départ et les heures
  /// quand le statut garde une arrivée.
  StaffAttendanceRecord mark(
    StaffAttendanceRecord record,
    StaffAttendanceStatus status,
    StaffClockTime now,
  ) {
    if (status == StaffAttendanceStatus.none) return clear(record);
    if (status == StaffAttendanceStatus.absent) {
      return _build(
        record,
        StaffAttendanceStatus.absent,
        justification: record.justification,
      );
    }
    final arrival = rules.suggestedArrival(status, now)!;
    final late = status == StaffAttendanceStatus.late;
    return _build(
      record,
      status,
      arrival: arrival,
      departure: _departureAfter(record.departure, arrival),
      lateMinutes: late ? arrival.minutesSince(rules.settings.start) : 0,
      workedMinutes: record.workedMinutes,
      justification: late ? record.justification : null,
    );
  }

  /// Saisit l'arrivée : le statut suit le classement, et repasser à l'heure
  /// retire la justification devenue sans objet.
  StaffAttendanceRecord setArrival(
    StaffAttendanceRecord record,
    StaffClockTime arrival,
  ) {
    final result = rules.classify(arrival);
    final late = result.status == StaffAttendanceStatus.late;
    return _build(
      record,
      result.status,
      arrival: arrival,
      departure: _departureAfter(record.departure, arrival),
      lateMinutes: result.lateMinutes,
      workedMinutes: record.workedMinutes,
      justification: late ? record.justification : null,
    );
  }

  /// Saisit ou efface le départ. Sans arrivée (absent, à pointer), rien ne
  /// change : un départ n'y a pas de sens.
  StaffAttendanceRecord setDeparture(
    StaffAttendanceRecord record,
    StaffClockTime? departure,
  ) {
    final arrival = record.arrival;
    if (!record.status.hasArrival || arrival == null) return record;
    // Un départ antérieur à l'arrivée est une saisie fausse : rien ne change,
    // plutôt que d'effacer en silence le départ existant.
    if (departure != null && departure.compareTo(arrival) < 0) return record;
    // Construit, pas copié : effacer le départ doit rendre `null`.
    return _build(
      record,
      record.status,
      arrival: arrival,
      departure: departure,
      lateMinutes: record.lateMinutes,
      workedMinutes: record.workedMinutes,
      justification: record.justification,
    );
  }

  /// Heures prestées d'un vacataire payé à l'heure, bornées à 0–10 h.
  StaffAttendanceRecord setWorked(StaffAttendanceRecord record, int minutes) {
    if (!record.status.hasArrival) return record;
    return _copy(
      record,
      workedMinutes: minutes.clamp(0, StaffAttendanceRecord.maxWorkedMinutes),
    );
  }

  /// Pose ou retire une justification — seulement sur un retard ou une
  /// absence.
  StaffAttendanceRecord justify(
    StaffAttendanceRecord record,
    StaffAttendanceJustification? justification,
  ) {
    if (!record.status.isIncident) return record;
    return _copy(record, justification: justification, dropJustification: true);
  }

  /// Remet « à pointer » : tout à vide, justification comprise.
  StaffAttendanceRecord clear(StaffAttendanceRecord record) =>
      _build(record, StaffAttendanceStatus.none);

  /// Un départ antérieur à l'arrivée n'est pas gardé.
  static StaffClockTime? _departureAfter(
    StaffClockTime? departure,
    StaffClockTime arrival,
  ) =>
      departure != null && departure.compareTo(arrival) >= 0 ? departure : null;

  static StaffAttendanceRecord _build(
    StaffAttendanceRecord record,
    StaffAttendanceStatus status, {
    StaffClockTime? arrival,
    StaffClockTime? departure,
    int lateMinutes = 0,
    int? workedMinutes,
    StaffAttendanceJustification? justification,
  }) => StaffAttendanceRecord(
    id: record.id,
    staffMemberId: record.staffMemberId,
    workDate: record.workDate,
    status: status,
    arrival: arrival,
    departure: departure,
    lateMinutes: lateMinutes,
    workedMinutes: workedMinutes,
    justification: justification,
    syncState: StaffSyncState.pending,
  );

  static StaffAttendanceRecord _copy(
    StaffAttendanceRecord record, {
    int? workedMinutes,
    StaffAttendanceJustification? justification,
    bool dropJustification = false,
  }) => _build(
    record,
    record.status,
    arrival: record.arrival,
    departure: record.departure,
    lateMinutes: record.lateMinutes,
    workedMinutes: workedMinutes ?? record.workedMinutes,
    justification: dropJustification ? justification : record.justification,
  );
}
