import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/staff/local/staff_attendance_settings_seed.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_lww.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_settings_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/core/presence/data/presence_schedule_reader.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Les réglages du Pointage d'une école (`ref_staff_attendance_settings`), et
/// l'année scolaire courante qui borne ses jours ouvrés.
class StaffAttendanceSettingsDao {
  final Database _db;

  const StaffAttendanceSettingsDao(this._db);

  static const String table = 'ref_staff_attendance_settings';
  static const String aggregateType = 'STAFF_ATTENDANCE_SETTINGS';

  static String entryId(String schoolId) => '$aggregateType:$schoolId';

  /// Les réglages de l'école ; les défauts quand elle n'a rien posé.
  Future<StaffAttendanceSettings> read(String schoolId) async {
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      limit: 1,
    );
    final schedule = rows.isEmpty
        ? null
        : PresenceScheduleReader.fromRow(rows.single);
    if (schedule == null) return StaffAttendanceSettings.defaults;
    return StaffAttendanceSettings(
      start: schedule.start,
      toleranceMinutes: schedule.toleranceMinutes,
      syncState: RecordSyncState.fromDb(rows.single['sync_status'] as String?),
    );
  }

  Future<void> applySeed(
    StaffAttendanceSettingsSeed seed, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final pending = await txn.query(
      table,
      columns: ['1'],
      where: 'school_id = ? AND sync_status = ?',
      whereArgs: [schoolId, RecordSyncState.pending.dbValue],
    );
    if (pending.isNotEmpty) return;
    await txn.insert(table, {
      'school_id': schoolId,
      'start_time': seed.startTime,
      'tolerance_minutes': seed.toleranceMinutes,
      'sync_status': RecordSyncState.synced.dbValue,
      'updated_at': nowMs,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  });

  /// Enregistre les réglages sur la tablette et les met en file (entrée
  /// unique par école : seul le dernier réglage part).
  Future<void> save(
    StaffAttendanceSettingsRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.insert(table, {
      'school_id': schoolId,
      'start_time': request.startTime,
      'tolerance_minutes': request.toleranceMinutes,
      'client_updated_at': request.clientUpdatedAt,
      'sync_status': RecordSyncState.pending.dbValue,
      'updated_at': nowMs,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await OutboxDao(txn).enqueue(
      OutboxEntry(
        id: entryId(schoolId),
        aggregateType: aggregateType,
        aggregateId: schoolId,
        operation: OutboxOperation.upsert,
        payload: jsonEncode(request.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
  });

  /// L'issue d'un envoi : accusé ([failed] `false`) ou refusé. Sans effet
  /// si les réglages ont été retouchés pendant le vol — rend alors `false` :
  /// la saisie plus récente partira avec sa propre entrée.
  Future<bool> settle(
    String schoolId, {
    required String sentClientUpdatedAt,
    required bool failed,
    String? code,
    String? reason,
  }) => _db.transaction((txn) async {
    final rows = await txn.query(
      table,
      columns: ['client_updated_at'],
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    if (rows.isEmpty ||
        !StaffLww.sameInstant(
          rows.single['client_updated_at'] as String?,
          sentClientUpdatedAt,
        )) {
      return false;
    }
    await txn.update(
      table,
      {
        'sync_status':
            (failed ? RecordSyncState.failed : RecordSyncState.synced).dbValue,
        'sync_error': reason,
        'sync_error_code': code,
      },
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    return true;
  });

  /// L'année scolaire courante de l'école, lue du socle d'Inscription ;
  /// `null` tant qu'il n'est pas descendu.
  Future<SchoolYearBounds?> currentSchoolYear(String schoolId) async {
    final rows = await _db.query(
      'ref_academic_years',
      columns: ['start_date', 'end_date'],
      where: 'school_id = ? AND is_current = 1',
      whereArgs: [schoolId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    String? day(Object? value) =>
        value is String && value.length >= 10 ? value.substring(0, 10) : null;
    return SchoolYearBounds(
      start: day(rows.single['start_date']),
      end: day(rows.single['end_date']),
    );
  }
}
