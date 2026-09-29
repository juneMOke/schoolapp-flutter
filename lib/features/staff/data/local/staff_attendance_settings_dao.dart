import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/staff/local/staff_attendance_settings_seed.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_lww.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_settings_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';
import 'package:sqflite_common/sqlite_api.dart';

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
    if (rows.isEmpty) return StaffAttendanceSettings.defaults;
    final row = rows.single;
    final start = StaffClockTime.tryParse(row['start_time'] as String?);
    final tolerance = row['tolerance_minutes'] as int?;
    if (start == null || tolerance == null) {
      return StaffAttendanceSettings.defaults;
    }
    return StaffAttendanceSettings(
      start: start,
      toleranceMinutes: tolerance,
      syncState: StaffSyncState.fromDb(row['sync_status'] as String?),
    );
  }

  /// La section du socle. Un réglage modifié sur la tablette et pas encore
  /// accusé n'est pas écrasé : il partira, et gagnera au dernier écrit.
  Future<void> applySeed(
    StaffAttendanceSettingsSeed seed, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final pending = await txn.query(
      table,
      columns: ['1'],
      where: 'school_id = ? AND sync_status != ?',
      whereArgs: [schoolId, StaffSyncState.synced.dbValue],
    );
    if (pending.isNotEmpty) return;
    await txn.insert(table, {
      'school_id': schoolId,
      'start_time': seed.startTime,
      'tolerance_minutes': seed.toleranceMinutes,
      'sync_status': StaffSyncState.synced.dbValue,
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
      'sync_status': StaffSyncState.pending.dbValue,
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
  /// si les réglages ont été retouchés pendant le vol.
  Future<void> settle(
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
      return;
    }
    await txn.update(
      table,
      {
        'sync_status':
            (failed ? StaffSyncState.failed : StaffSyncState.synced).dbValue,
        'sync_error': reason,
        'sync_error_code': code,
      },
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
  });

  /// L'année scolaire courante de l'école, lue du socle d'Inscription ;
  /// `null` tant qu'il n'est pas descendu.
  Future<StaffSchoolYear?> currentSchoolYear(String schoolId) async {
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
    return StaffSchoolYear(
      start: day(rows.single['start_date']),
      end: day(rows.single['end_date']),
    );
  }
}
