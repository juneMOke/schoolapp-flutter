import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une ligne de `staff_attendance_records`, et ses passages vers l'entité et
/// le fil.
class StaffAttendanceLocalModel {
  final Map<String, Object?> row;

  const StaffAttendanceLocalModel(this.row);

  static const String table = 'staff_attendance_records';

  /// Les colonnes de contenu d'un pointage tel qu'il circule sur le fil.
  static Map<String, Object?> contentColumns(StaffAttendanceDto dto) => {
    'staff_member_id': dto.staffMemberId,
    'work_date': dto.workDate,
    'status': dto.status,
    'arrival_time': dto.arrivalTime,
    'departure_time': dto.departureTime,
    'late_minutes': dto.lateMinutes,
    'worked_minutes': dto.workedMinutes,
    'justification_reason': dto.justificationReason,
    'justification_note': dto.justificationNote,
    'client_updated_at': dto.clientUpdatedAt,
  };

  /// Ce que seul le serveur écrit.
  static Map<String, Object?> serverColumns(StaffAttendanceDto dto) => {
    'version': dto.version,
    'server_updated_at': dto.serverUpdatedAt,
  };

  /// Le fil d'un pointage saisi sur la tablette, horodaté [clientUpdatedAt].
  static StaffAttendanceDto toWire(
    StaffAttendanceRecord record, {
    required String clientUpdatedAt,
  }) => StaffAttendanceDto(
    id: record.id,
    staffMemberId: record.staffMemberId,
    workDate: record.workDate,
    status: record.status.staffWire,
    arrivalTime: record.arrival?.wire,
    departureTime: record.departure?.wire,
    lateMinutes: record.lateMinutes,
    workedMinutes: record.workedMinutes,
    justificationReason: record.justification?.reason.wire,
    justificationNote: record.justification?.note,
    clientUpdatedAt: clientUpdatedAt,
  );

  String get id => (row['id'] as String?) ?? '';
  String get workDate => (row['work_date'] as String?) ?? '';
  String? get clientUpdatedAt => row['client_updated_at'] as String?;
  RecordSyncState get syncState =>
      RecordSyncState.fromDb(row['sync_status'] as String?);

  StaffAttendanceRecord toEntity() {
    String? text(String key) => row[key] as String?;
    final reason = StaffAbsenceReason.fromWire(text('justification_reason'));
    return StaffAttendanceRecord(
      id: id,
      staffMemberId: text('staff_member_id') ?? '',
      workDate: workDate,
      // Un statut que ce poste ne connaît pas se lit « à pointer » : c'est
      // l'état qui n'affirme rien de faux.
      status:
          StaffPresenceWire.fromStaffWire(text('status')) ??
          PresenceStatus.none,
      arrival: ClockTime.tryParse(text('arrival_time')),
      departure: ClockTime.tryParse(text('departure_time')),
      lateMinutes: (row['late_minutes'] as int?) ?? 0,
      workedMinutes: row['worked_minutes'] as int?,
      justification: reason == null
          ? null
          : StaffAttendanceJustification(
              reason: reason,
              note: text('justification_note'),
            ),
      syncState: syncState,
      syncErrorCode: text('sync_error_code'),
    );
  }
}
