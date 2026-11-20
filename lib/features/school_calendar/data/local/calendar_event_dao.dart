import 'dart:math' as math;

import 'package:school_app_flutter/core/database/schema/school_calendar_schema.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/school_calendar/data/wire/calendar_wire.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_actor.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les événements de l'école sur l'appareil : descendus, écrits ici, envoyés.
///
/// Dernier écrit gagne **par événement** (K11) : l'horloge `client_updated_at`
/// d'un geste est monotone — elle bat toujours la précédente et ce que le
/// serveur a déjà, même si l'horloge du poste a reculé. Les réconciliations
/// sont gardées par `client_updated_at = pushedAt AND sync_status = PENDING` :
/// un geste plus récent, fait pendant l'envoi, n'est jamais écrasé.
class CalendarEventDao {
  final DatabaseExecutor _db;

  const CalendarEventDao(this._db);

  static final String _table = schoolCalendarEventsTable.name;

  /// Une page de `calendar.events`. Une ligne qui porte un geste en attente
  /// n'est pas touchée : son envoi dira qui gagne (SUPERSEDED).
  Future<int> applyPulled(
    List<PulledEvent> rows, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (rows.isEmpty || schoolId.isEmpty) return 0;
    final batch = _db.batch();
    for (final row in rows) {
      final values = _row(row.record, schoolId: schoolId, nowMs: nowMs)
        ..['server_updated_at'] = row.serverUpdatedAtMs
        ..['sync_status'] = RecordSyncState.synced.dbValue;
      batch.rawInsert(
        'INSERT INTO $_table (${values.keys.join(', ')}) '
        'VALUES (${List.filled(values.length, '?').join(', ')}) '
        'ON CONFLICT(id) DO UPDATE SET '
        '${[for (final k in values.keys)
          if (k != 'id') '$k = excluded.$k'].join(', ')} '
        "WHERE $_table.sync_status <> '${RecordSyncState.pending.dbValue}'",
        values.values.toList(),
      );
    }
    await batch.commit(noResult: true);
    return rows.length;
  }

  /// Pose un geste (ajout, modification, « date vérifiée », suppression) et
  /// rend l'horloge posée. À appeler dans la transaction qui enfile l'envoi.
  static Future<int> saveLocal(
    DatabaseExecutor txn,
    SchoolEventRecord record, {
    required String schoolId,
    required int nowMs,
  }) async {
    final rows = await txn.query(
      _table,
      columns: ['client_updated_at', 'server_updated_at'],
      where: 'id = ?',
      whereArgs: [record.element.id],
    );
    final last = rows.isEmpty
        ? 0
        : math.max(
            rows.first['client_updated_at'] as int? ?? 0,
            rows.first['server_updated_at'] as int? ?? 0,
          );
    final at = math.max(nowMs, last + 1);
    final values = _row(
      SchoolEventRecord(
        element: record.element,
        calendarId: record.calendarId,
        clientUpdatedAtMs: at,
        deleted: record.deleted,
      ),
      schoolId: schoolId,
      nowMs: nowMs,
    )..['sync_status'] = RecordSyncState.pending.dbValue;
    await txn.insert(
      _table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return at;
  }

  /// Les gestes à envoyer, du plus ancien au plus récent.
  Future<List<SchoolEventRecord>> pending(
    String schoolId, {
    int limit = 200,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'school_id = ? AND sync_status = ?',
      whereArgs: [schoolId, RecordSyncState.pending.dbValue],
      orderBy: 'client_updated_at, id',
      limit: limit,
    );
    return [for (final r in rows) _recordOf(r)];
  }

  Future<int> pendingCount(String schoolId, {String? calendarId}) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM $_table WHERE school_id = ? AND sync_status = ?'
      '${calendarId == null ? '' : ' AND calendar_id = ?'}',
      [schoolId, RecordSyncState.pending.dbValue, ?calendarId],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  /// APPLIED ou SUPERSEDED : l'état du serveur remplace la ligne envoyée.
  Future<void> applyServerState({
    required String id,
    required int pushedAt,
    required PulledEvent server,
    required bool superseded,
    required String schoolId,
    required int nowMs,
  }) async {
    final values = _row(server.record, schoolId: schoolId, nowMs: nowMs)
      ..remove('id')
      ..['server_updated_at'] = server.serverUpdatedAtMs
      ..['sync_status'] = RecordSyncState.synced.dbValue
      ..['sync_error_code'] = null
      ..['superseded_at'] = superseded ? nowMs : null;
    await _db.update(
      _table,
      values,
      where: 'id = ? AND client_updated_at = ? AND sync_status = ?',
      whereArgs: [id, pushedAt, RecordSyncState.pending.dbValue],
    );
  }

  /// APPLIED sans état rendu : la ligne envoyée fait foi.
  Future<void> markSynced({required String id, required int pushedAt}) =>
      _db.update(
        _table,
        {
          'sync_status': RecordSyncState.synced.dbValue,
          'sync_error_code': null,
        },
        where: 'id = ? AND client_updated_at = ? AND sync_status = ?',
        whereArgs: [id, pushedAt, RecordSyncState.pending.dbValue],
      );

  /// REJECTED : la ligne reste à l'écran, marquée, avec son code (CAL-I19).
  /// Une suppression refusée n'a pas eu lieu : l'événement revient, marqué.
  Future<void> markRejected({
    required String id,
    required int pushedAt,
    required String? code,
  }) => _db.update(
    _table,
    {
      'sync_status': RecordSyncState.failed.dbValue,
      'sync_error_code': code,
      'deleted': 0,
    },
    where: 'id = ? AND client_updated_at = ? AND sync_status = ?',
    whereArgs: [id, pushedAt, RecordSyncState.pending.dbValue],
  );

  /// Les événements d'un calendrier, sans les supprimés.
  Future<List<SchoolEventRecord>> eventsOf(String calendarId) async {
    final rows = await _db.query(
      _table,
      where: 'calendar_id = ? AND deleted = 0',
      whereArgs: [calendarId],
      orderBy: 'start_date, id',
    );
    return [for (final r in rows) _recordOf(r)];
  }

  /// Les événements écrasés par un autre appareil depuis la dernière lecture,
  /// rendus une fois (l'écran prévient) puis effacés.
  Future<List<SchoolEventRecord>> takeSuperseded(String calendarId) async {
    final rows = await _db.query(
      _table,
      where: 'calendar_id = ? AND superseded_at IS NOT NULL',
      whereArgs: [calendarId],
    );
    if (rows.isEmpty) return const [];
    await _db.update(
      _table,
      {'superseded_at': null},
      where: 'calendar_id = ? AND superseded_at IS NOT NULL',
      whereArgs: [calendarId],
    );
    return [for (final r in rows) _recordOf(r)];
  }

  static Map<String, Object?> _row(
    SchoolEventRecord record, {
    required String schoolId,
    required int nowMs,
  }) {
    final e = record.element;
    return {
      'id': e.id,
      'school_id': schoolId,
      'calendar_id': record.calendarId,
      'nature': e.nature.wire,
      'title': e.title,
      'start_date': CalendarDays.format(e.startDate),
      'end_date': CalendarDays.format(e.endDate),
      'scope': e.scope.wire,
      'note': e.note,
      'to_verify': e.toVerify ? 1 : 0,
      'created_by_name': e.createdBy?.name,
      'created_by_role': e.createdBy?.role,
      'client_updated_at': record.clientUpdatedAtMs,
      'deleted': record.deleted ? 1 : 0,
      'synced_at': nowMs,
    };
  }

  static SchoolEventRecord _recordOf(Map<String, Object?> r) =>
      SchoolEventRecord(
        element: CalendarElement(
          id: r['id']! as String,
          source: CalendarSource.school,
          nature: CalendarNature.fromWire(r['nature'] as String?),
          title: r['title']! as String,
          startDate: CalendarDays.tryParse(r['start_date'] as String?)!,
          endDate: CalendarDays.tryParse(r['end_date'] as String?)!,
          scope: CalendarScope.parse(r['scope'] as String?),
          note: r['note'] as String?,
          toVerify: r['to_verify'] == 1,
          createdBy:
              r['created_by_name'] == null && r['created_by_role'] == null
              ? null
              : CalendarActor(
                  name: r['created_by_name'] as String?,
                  role: r['created_by_role'] as String?,
                ),
        ),
        calendarId: r['calendar_id']! as String,
        clientUpdatedAtMs: (r['client_updated_at'] as int?) ?? 0,
        deleted: r['deleted'] == 1,
        syncState: RecordSyncState.fromDb(r['sync_status'] as String?),
        errorCode: r['sync_error_code'] as String?,
        superseded: r['superseded_at'] != null,
      );
}
