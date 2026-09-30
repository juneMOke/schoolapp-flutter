import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_lock_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les gestes de verrou posés sur la tablette (`staff_attendance_gestures`) :
/// leur pose avec l'entrée d'outbox, leur issue, et les gardes d'ordre qui
/// les lisent.
///
/// **« En file » = entrée d'outbox en attente ET geste pas encore accusé**,
/// jamais `sync_status` seul : une entrée empoisonnée ou refusée sans passer
/// par [mark] laisserait sinon un geste « en attente » pour toujours, et tous
/// ceux qui l'attendent gelés avec lui. Et un geste accusé ne retient plus
/// personne, même avant que le moteur n'acquitte son entrée.
class StaffAttendanceGestureDao {
  final Database _db;

  const StaffAttendanceGestureDao(this._db);

  static const String table = 'staff_attendance_gestures';
  static const String aggregateType = 'STAFF_ATTENDANCE_GESTURE';

  static String entryId(String gestureId) => '$aggregateType:$gestureId';

  /// Jointure d'un geste `g` à son entrée d'outbox `o`.
  static const String _outboxOn =
      "${OutboxDao.table} o ON o.id = '$aggregateType:' || g.id";
  static const String _joinOutbox = 'JOIN $_outboxOn';

  /// Pose un geste et le met en file, dans une transaction. Une entrée par
  /// geste : deux gestes ne fusionnent jamais, sinon « rouvrir, corriger,
  /// valider » ne laisserait partir que la validation.
  Future<void> add(
    StaffAttendanceGestureRequestDto request, {
    required StaffAttendanceLockKind kind,
    required String? authorName,
    required String recordedAt,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.insert(table, {
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
        id: entryId(request.gestureId),
        aggregateType: aggregateType,
        aggregateId: '${kind.wire}:${request.date}',
        operation: OutboxOperation.create,
        payload: jsonEncode(request.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
  });

  /// Les gestes des périodes [from] → [to], dans l'ordre de pose, avec
  /// `queued` = 1 quand leur entrée d'outbox est encore en file.
  Future<List<Map<String, Object?>>> inRange(
    String schoolId, {
    required String from,
    required String to,
  }) => _db.rawQuery(
    'SELECT g.*, (o.status = ?) AS queued FROM $table g '
    'LEFT JOIN $_outboxOn '
    'WHERE g.school_id = ? AND g.period_start >= ? AND g.period_start <= ? '
    'ORDER BY g.created_at ASC, g.rowid ASC',
    [OutboxStatus.pending.dbValue, schoolId, from, to],
  );

  /// Un geste **encore en file** sur ces périodes, posé strictement avant
  /// [gestureId] ? Un geste attend ses aînés : jamais deux dans le désordre.
  /// L'ordre est strict — `(created_at, rowid)` —, sinon deux gestes posés
  /// dans la même milliseconde s'attendraient l'un l'autre à jamais.
  Future<bool> hasOlderQueued(
    String schoolId, {
    required String gestureId,
    required String from,
    required String to,
  }) => _exists(
    'SELECT 1 FROM $table g $_joinOutbox '
    'JOIN $table me ON me.id = ? '
    'WHERE g.school_id = ? AND g.id != me.id AND o.status = ? '
    'AND g.sync_status = ? '
    'AND g.period_start >= ? AND g.period_start <= ? '
    'AND (g.created_at < me.created_at '
    'OR (g.created_at = me.created_at AND g.rowid < me.rowid)) LIMIT 1',
    [
      gestureId,
      schoolId,
      OutboxStatus.pending.dbValue,
      StaffSyncState.pending.dbValue,
      from,
      to,
    ],
  );

  /// Une réouverture de [day], posée au plus tard à [queuedBefore], est-elle
  /// encore en file ? Un pointage du jour attend alors derrière elle, sinon il
  /// reviendrait `DAY_LOCKED`. Jamais une réouverture posée après lui : elle
  /// attend peut-être elle-même une validation qui l'attend.
  Future<bool> hasQueuedReopen(
    String schoolId,
    String day, {
    required int queuedBefore,
  }) => _exists(
    'SELECT 1 FROM $table g $_joinOutbox '
    'WHERE g.school_id = ? AND g.period_start = ? AND g.gesture = ? '
    'AND o.status = ? AND g.sync_status = ? AND g.created_at <= ? LIMIT 1',
    [
      schoolId,
      day,
      StaffAttendanceGesture.reopenDay.wire,
      OutboxStatus.pending.dbValue,
      StaffSyncState.pending.dbValue,
      queuedBefore,
    ],
  );

  Future<void> mark(
    String gestureId,
    StaffSyncState state, {
    String? code,
    String? reason,
  }) => _db.update(
    table,
    {
      'sync_status': state.dbValue,
      'sync_error': reason,
      'sync_error_code': code,
    },
    where: 'id = ?',
    whereArgs: [gestureId],
  );

  Future<bool> _exists(String sql, List<Object?> args) async =>
      (await _db.rawQuery(sql, args)).isNotEmpty;
}
