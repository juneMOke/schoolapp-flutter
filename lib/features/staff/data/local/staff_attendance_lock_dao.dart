import 'package:school_app_flutter/features/staff/data/local/staff_attendance_gesture_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_lock_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Les verrous du Pointage : l'état du serveur (`staff_attendance_locks`), et
/// ce que l'écran en montre une fois les gestes de la tablette pris en compte
/// ([StaffAttendanceGestureDao]).
///
/// **Ce que l'écran montre** : le dernier geste de la tablette tant qu'il est
/// en file ; sinon l'état du serveur. Un geste refusé — ou dont l'entrée
/// d'outbox a disparu de la file — laisse l'état du serveur, marqué en échec.
class StaffAttendanceLockDao {
  final Database _db;
  final StaffAttendanceGestureDao _gestures;

  StaffAttendanceLockDao(this._db) : _gestures = StaffAttendanceGestureDao(_db);

  static const String locksTable = 'staff_attendance_locks';

  /// Applique des états serveur (flux ou accusé). Rend le nombre écrit.
  ///
  /// Un jour qui **passe de validé à rouvert** — rouvert ici ou sur une autre
  /// tablette — remet en file ses pointages refusés `DAY_LOCKED`, dans la
  /// même transaction.
  Future<int> applyServer(
    List<StaffAttendanceLockDto> locks, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (locks.isEmpty || schoolId.isEmpty) return 0;
    await _db.transaction((txn) async {
      for (final lock in locks) {
        const where = 'school_id = ? AND kind = ? AND period_start = ?';
        final args = [schoolId, lock.kind, lock.periodStart];
        final before = await txn.query(
          locksTable,
          columns: ['locked'],
          where: where,
          whereArgs: args,
        );
        await txn.insert(locksTable, {
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
        final reopened =
            !lock.isLocked && before.isNotEmpty && before.single['locked'] == 1;
        if (reopened && lock.kind == StaffAttendanceLockKind.day.wire) {
          await StaffAttendanceSyncDao.requeueDayLockedIn(
            txn,
            schoolId,
            lock.periodStart,
            nowMs: nowMs,
          );
        }
        if (reopened && lock.kind == StaffAttendanceLockKind.month.wire) {
          await _requeueMonthClosedIn(txn, schoolId, lock.periodStart, nowMs);
        }
      }
    });
    return locks.length;
  }

  /// Remet en file les pointages `DAY_LOCKED` d'un jour rouvert. Appelé à
  /// l'accusé d'une réouverture de la tablette, que la ligne du verrou ait
  /// déjà été descendue ou non (idempotent).
  Future<int> requeueDayLocked(
    String schoolId,
    String day, {
    required int nowMs,
  }) => _db.transaction(
    (txn) => StaffAttendanceSyncDao.requeueDayLockedIn(
      txn,
      schoolId,
      day,
      nowMs: nowMs,
    ),
  );

  /// Remet en file les pointages `MONTH_CLOSED` d'un mois rouvert. Appelé à
  /// l'accusé d'une réouverture de la tablette (idempotent).
  Future<int> requeueMonthClosed(
    String schoolId,
    String monthStart, {
    required int nowMs,
  }) => _db.transaction(
    (txn) => _requeueMonthClosedIn(txn, schoolId, monthStart, nowMs),
  );

  static Future<int> _requeueMonthClosedIn(
    DatabaseExecutor txn,
    String schoolId,
    String monthStart,
    int nowMs,
  ) {
    final days = SchoolDayCalendar.daysOf(
      SchoolDayCalendar.monthOf(monthStart),
    );
    return StaffAttendanceSyncDao.requeueMonthClosedIn(
      txn,
      schoolId,
      from: days.first,
      to: days.last,
      nowMs: nowMs,
    );
  }

  /// Les verrous tels que l'écran les montre, périodes [from] → [to].
  Future<List<StaffAttendanceLock>> effective(
    String schoolId, {
    required String from,
    required String to,
  }) async {
    if (schoolId.isEmpty) return const [];
    final server = await _db.query(
      locksTable,
      where: 'school_id = ? AND period_start >= ? AND period_start <= ?',
      whereArgs: [schoolId, from, to],
    );
    final gestures = await _gestures.inRange(schoolId, from: from, to: to);
    final byKey = <String, StaffAttendanceLock>{
      for (final row in server)
        _key(row): _fromServer(row, RecordSyncState.synced),
    };
    final latest = <String, Map<String, Object?>>{
      for (final gesture in gestures) _key(gesture): gesture,
    };
    for (final MapEntry(key: key, value: gesture) in latest.entries) {
      final state = _stateOf(gesture);
      if (state == RecordSyncState.synced) continue;
      if (state == RecordSyncState.failed) {
        final current = byKey[key];
        final code = gesture['sync_error_code'] as String?;
        byKey[key] = current == null
            ? StaffAttendanceLock(
                kind: _kind(gesture),
                periodStart: gesture['period_start']! as String,
                locked: false,
                syncState: RecordSyncState.failed,
                syncErrorCode: code,
              )
            : _withState(current, RecordSyncState.failed, code: code);
        continue;
      }
      byKey[key] = StaffAttendanceLock(
        kind: _kind(gesture),
        periodStart: gesture['period_start']! as String,
        locked:
            StaffAttendanceGesture.fromWire(
              gesture['gesture'] as String?,
            )?.locks ??
            false,
        lockedAt: gesture['recorded_at'] as String?,
        lockedByName: gesture['author_name'] as String?,
        syncState: RecordSyncState.pending,
      );
    }
    return byKey.values.toList(growable: false);
  }

  /// En attente seulement si l'entrée d'outbox est encore en file ; sinon le
  /// geste ne partira plus, et se lit comme refusé.
  static RecordSyncState _stateOf(Map<String, Object?> gesture) {
    final state = RecordSyncState.fromDb(gesture['sync_status'] as String?);
    if (state != RecordSyncState.pending) return state;
    return gesture['queued'] == 1 ? state : RecordSyncState.failed;
  }

  static String _key(Map<String, Object?> row) =>
      '${row['kind']}:${row['period_start']}';

  static StaffAttendanceLockKind _kind(Map<String, Object?> row) =>
      StaffAttendanceLockKind.fromWire(row['kind'] as String?) ??
      StaffAttendanceLockKind.day;

  static StaffAttendanceLock _fromServer(
    Map<String, Object?> row,
    RecordSyncState state,
  ) => StaffAttendanceLock(
    kind: _kind(row),
    periodStart: row['period_start']! as String,
    locked: row['locked'] == 1,
    lockedAt: row['locked_at'] as String?,
    lockedByName: row['locked_by_name'] as String?,
    syncState: state,
  );

  static StaffAttendanceLock _withState(
    StaffAttendanceLock lock,
    RecordSyncState state, {
    String? code,
  }) => StaffAttendanceLock(
    kind: lock.kind,
    periodStart: lock.periodStart,
    locked: lock.locked,
    lockedAt: lock.lockedAt,
    lockedByName: lock.lockedByName,
    syncState: state,
    syncErrorCode: code,
  );
}
