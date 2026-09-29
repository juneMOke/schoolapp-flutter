import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_lock_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les verrous du Pointage : l'état du serveur (`staff_attendance_locks`) et
/// les gestes posés sur la tablette (`staff_attendance_gestures`).
///
/// **Ce que l'écran montre** : le dernier geste de la tablette tant qu'il
/// n'est pas accusé ; sinon l'état du serveur. Un geste refusé laisse l'état
/// du serveur, marqué en échec pour que l'écran propose de réessayer.
class StaffAttendanceLockDao {
  final Database _db;

  const StaffAttendanceLockDao(this._db);

  static const String locksTable = 'staff_attendance_locks';
  static const String gesturesTable = 'staff_attendance_gestures';
  static const String gestureAggregateType = 'STAFF_ATTENDANCE_GESTURE';

  static String gestureEntryId(String gestureId) =>
      '$gestureAggregateType:$gestureId';

  /// Applique des états serveur (flux ou accusé). Rend le nombre écrit.
  Future<int> applyServer(
    List<StaffAttendanceLockDto> locks, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (locks.isEmpty || schoolId.isEmpty) return 0;
    final batch = _db.batch();
    for (final lock in locks) {
      batch.insert(locksTable, {
        'school_id': schoolId,
        'kind': lock.kind,
        'period_start': lock.periodStart,
        'locked': lock.isLocked ? 1 : 0,
        'locked_at': lock.lockedAt,
        'locked_by_name': lock.lockedByName,
        'version': lock.version,
        'server_updated_at': lock.serverUpdatedAt,
        'updated_at': nowMs,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return locks.length;
  }

  /// Pose un geste sur la tablette et le met en file, dans une transaction.
  /// Une entrée par geste (`STAFF_ATTENDANCE_GESTURE:<gestureId>`) : deux
  /// gestes ne fusionnent jamais, sinon « rouvrir, corriger, valider » ne
  /// laisserait partir que la validation.
  Future<void> addGesture(
    StaffAttendanceGestureRequestDto request, {
    required StaffAttendanceLockKind kind,
    required String? authorName,
    required String recordedAt,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.insert(gesturesTable, {
      'id': request.gestureId,
      'school_id': schoolId,
      'kind': kind.wire,
      'period_start': request.date,
      'gesture': request.gesture,
      'recorded_at': recordedAt,
      'author_name': authorName,
      'sync_status': StaffSyncState.pending.dbValue,
      'created_at': nowMs,
    });
    await OutboxDao(txn).enqueue(
      OutboxEntry(
        id: gestureEntryId(request.gestureId),
        aggregateType: gestureAggregateType,
        aggregateId: '${kind.wire}:${request.date}',
        operation: OutboxOperation.create,
        payload: jsonEncode(request.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
  });

  /// Les verrous tels que l'écran les montre, périodes [from] → [to].
  Future<List<StaffAttendanceLock>> effective(
    String schoolId, {
    required String from,
    required String to,
  }) async {
    if (schoolId.isEmpty) return const [];
    const where = 'school_id = ? AND period_start >= ? AND period_start <= ?';
    final args = [schoolId, from, to];
    final server = await _db.query(locksTable, where: where, whereArgs: args);
    final gestures = await _db.query(
      gesturesTable,
      where: where,
      whereArgs: args,
      orderBy: 'created_at ASC, rowid ASC',
    );
    final latest = <String, Map<String, Object?>>{
      for (final gesture in gestures) _key(gesture): gesture,
    };
    final byKey = <String, StaffAttendanceLock>{};
    for (final row in server) {
      byKey[_key(row)] = _fromServer(row, StaffSyncState.synced);
    }
    for (final MapEntry(key: key, value: gesture) in latest.entries) {
      final state = StaffSyncState.fromDb(gesture['sync_status'] as String?);
      if (state == StaffSyncState.synced) continue;
      if (state == StaffSyncState.failed) {
        final serverRow = _serverRowOf(server, key);
        byKey[key] = serverRow == null
            ? _unlocked(gesture, StaffSyncState.failed)
            : _fromServer(serverRow, StaffSyncState.failed);
        continue;
      }
      final action = StaffAttendanceGesture.fromWire(
        gesture['gesture'] as String?,
      );
      byKey[key] = StaffAttendanceLock(
        kind: _kind(gesture),
        periodStart: gesture['period_start']! as String,
        locked: action?.locks ?? false,
        lockedAt: gesture['recorded_at'] as String?,
        lockedByName: gesture['author_name'] as String?,
        syncState: StaffSyncState.pending,
      );
    }
    return byKey.values.toList(growable: false);
  }

  /// Un geste encore en attente sur une de ces périodes, posé avant
  /// [createdAt] ? Un geste attend ses aînés : jamais deux dans le désordre.
  Future<bool> hasOlderPendingGesture(
    String schoolId, {
    required String gestureId,
    required int createdAt,
    required String from,
    required String to,
  }) => _exists(
    gesturesTable,
    'school_id = ? AND id != ? AND sync_status = ? AND created_at <= ? '
    'AND period_start >= ? AND period_start <= ?',
    [schoolId, gestureId, StaffSyncState.pending.dbValue, createdAt, from, to],
  );

  /// Une réouverture de [day] attend-elle encore son accusé ? Un pointage du
  /// jour attend alors derrière elle, sinon il reviendrait `DAY_LOCKED`.
  Future<bool> hasPendingReopen(String schoolId, String day) => _exists(
    gesturesTable,
    'school_id = ? AND period_start = ? AND gesture = ? AND sync_status = ?',
    [
      schoolId,
      day,
      StaffAttendanceGesture.reopenDay.wire,
      StaffSyncState.pending.dbValue,
    ],
  );

  Future<void> markGesture(
    String gestureId,
    StaffSyncState state, {
    String? code,
    String? reason,
  }) => _db.update(
    gesturesTable,
    {
      'sync_status': state.dbValue,
      'sync_error': reason,
      'sync_error_code': code,
    },
    where: 'id = ?',
    whereArgs: [gestureId],
  );

  Future<bool> _exists(String table, String where, List<Object?> args) async {
    final rows = await _db.query(
      table,
      columns: ['1'],
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static String _key(Map<String, Object?> row) =>
      '${row['kind']}:${row['period_start']}';

  static Map<String, Object?>? _serverRowOf(
    List<Map<String, Object?>> server,
    String key,
  ) {
    for (final row in server) {
      if (_key(row) == key) return row;
    }
    return null;
  }

  static StaffAttendanceLockKind _kind(Map<String, Object?> row) =>
      StaffAttendanceLockKind.fromWire(row['kind'] as String?) ??
      StaffAttendanceLockKind.day;

  static StaffAttendanceLock _fromServer(
    Map<String, Object?> row,
    StaffSyncState state,
  ) => StaffAttendanceLock(
    kind: _kind(row),
    periodStart: row['period_start']! as String,
    locked: row['locked'] == 1,
    lockedAt: row['locked_at'] as String?,
    lockedByName: row['locked_by_name'] as String?,
    syncState: state,
  );

  static StaffAttendanceLock _unlocked(
    Map<String, Object?> gesture,
    StaffSyncState state,
  ) => StaffAttendanceLock(
    kind: _kind(gesture),
    periodStart: gesture['period_start']! as String,
    locked: false,
    syncState: state,
  );
}
