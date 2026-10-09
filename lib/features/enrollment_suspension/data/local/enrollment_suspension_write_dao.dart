import 'dart:convert';

import 'package:school_app_flutter/core/database/projections/enrollment_suspension_sql.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_row.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_gesture.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écriture des gestes de désactivation — **chaque geste avec son entrée
/// d'outbox et sa projection sur le membre de classe, dans une seule
/// transaction pour tout le lot** : la tablette applique un lot de N élèves
/// en entier ou pas du tout.
///
/// Une entrée par geste (`ENROLLMENT_SUSPENSION:<id du geste>`), jamais
/// remplacée : une réactivation suit la désactivation qu'elle ferme, et le
/// handler les envoie dans l'ordre de l'inscription.
class EnrollmentSuspensionWriteDao {
  final Database _db;

  const EnrollmentSuspensionWriteDao(this._db);

  static const String table = EnrollmentSuspensionRow.table;
  static const String aggregateType = EnrollmentSuspensionSql.aggregateType;

  static String entryId(String gestureId) => '$aggregateType:$gestureId';

  /// Ouvre une période pour chaque geste ; rend les inscriptions effectivement
  /// désactivées. Une inscription déjà désactivée est ignorée (sans effet).
  Future<Set<String>> suspend(
    List<SuspensionGesture> gestures, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final applied = <String>{};
    final students = <(String, String)>{};
    for (final g in gestures) {
      assert(g.op == SuspensionGestureOp.suspend);
      if (await _openPeriod(txn, g.enrollmentId) != null) continue;
      await txn.insert(table, {
        'id': g.id,
        'school_id': schoolId,
        'enrollment_id': g.enrollmentId,
        'student_id': g.studentId,
        'academic_year_id': g.academicYearId,
        'suspended_at': g.at,
        'suspended_by': g.authorId,
        'reason': g.reason?.wire,
        'precision': g.precision,
        ..._pending(g.op, nowMs),
      });
      await _enqueue(txn, g, schoolId: schoolId, nowMs: nowMs);
      applied.add(g.enrollmentId);
      students.add((g.studentId, g.academicYearId));
    }
    await EnrollmentSuspensionSql.project(txn, students);
    return applied;
  });

  /// Ferme la période ouverte de chaque geste ; rend les inscriptions
  /// effectivement réactivées. Sans période ouverte, le geste est ignoré.
  Future<Set<String>> reactivate(
    List<SuspensionGesture> gestures, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final applied = <String>{};
    final students = <(String, String)>{};
    for (final g in gestures) {
      assert(g.op == SuspensionGestureOp.reactivate);
      final open = await _openPeriod(txn, g.enrollmentId);
      if (open == null) continue;
      await txn.update(
        table,
        {
          'reactivation_id': g.id,
          'reactivated_at': g.at,
          'reactivated_by': g.authorId,
          ..._pending(g.op, nowMs),
        },
        where: 'id = ?',
        whereArgs: [open.id],
      );
      await _enqueue(txn, g, schoolId: schoolId, nowMs: nowMs);
      applied.add(g.enrollmentId);
      students.add((open.studentId, open.academicYearId));
    }
    await EnrollmentSuspensionSql.project(txn, students);
    return applied;
  });

  static Map<String, Object?> _pending(SuspensionGestureOp op, int nowMs) => {
    'pending_op': op.wire,
    'sync_status': RecordSyncState.pending.dbValue,
    'sync_error': null,
    'sync_error_code': null,
    'updated_at': nowMs,
  };

  static Future<EnrollmentSuspensionRow?> _openPeriod(
    DatabaseExecutor txn,
    String enrollmentId,
  ) async {
    final rows = await txn.query(
      table,
      where: 'enrollment_id = ? AND reactivated_at IS NULL',
      whereArgs: [enrollmentId],
      limit: 1,
    );
    return rows.isEmpty ? null : EnrollmentSuspensionRow(rows.single);
  }

  static Future<void> _enqueue(
    DatabaseExecutor txn,
    SuspensionGesture g, {
    required String schoolId,
    required int nowMs,
  }) => OutboxDao(txn).enqueue(
    OutboxEntry(
      id: entryId(g.id),
      aggregateType: aggregateType,
      aggregateId: g.enrollmentId,
      operation: g.op == SuspensionGestureOp.suspend
          ? OutboxOperation.create
          : OutboxOperation.update,
      payload: jsonEncode(g.toJson()),
      schoolId: schoolId,
      createdAt: nowMs,
    ),
  );
}
