import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écriture d'une correction de niveau — **la ligne et son entrée d'outbox dans
/// une seule transaction** : le geste existe en entier ou pas du tout.
///
/// Une entrée par geste (`ENROLLMENT_LEVEL_CORRECTION:<id du geste>`), jamais
/// remplacée, rattachée à l'inscription (`aggregate_id`) pour que le handler
/// garde l'ordre des gestes d'un même élève.
class LevelCorrectionWriteDao {
  final Database _db;

  const LevelCorrectionWriteDao(this._db);

  static const String table = 'enrollment_level_corrections';
  static const String aggregateType = 'ENROLLMENT_LEVEL_CORRECTION';

  static String entryId(String gestureId) => '$aggregateType:$gestureId';

  /// Pose [gesture] ; rend `false` sans rien écrire si une correction de la
  /// même inscription attend déjà. La seconde partirait avec un niveau de
  /// départ périmé, et le serveur la refuserait en `STALE_LEVEL`.
  Future<bool> record(
    LevelCorrectionGesture gesture, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final pending = await txn.query(
      table,
      columns: ['id'],
      where: 'enrollment_id = ? AND sync_status = ?',
      whereArgs: [gesture.enrollmentId, RecordSyncState.pending.dbValue],
      limit: 1,
    );
    if (pending.isNotEmpty) return false;
    await txn.insert(table, {
      'id': gesture.id,
      'school_id': schoolId,
      'enrollment_id': gesture.enrollmentId,
      'student_id': gesture.studentId,
      'academic_year_id': gesture.academicYearId,
      'from_school_level_id': gesture.fromSchoolLevelId,
      'to_school_level_id': gesture.toSchoolLevelId,
      'to_school_level_group_id': gesture.toSchoolLevelGroupId,
      'to_classroom_id': gesture.toClassroomId,
      'reason': gesture.reason,
      'corrected_at': gesture.correctedAt,
      'corrected_by': gesture.authorId,
      'sync_status': RecordSyncState.pending.dbValue,
      'updated_at': nowMs,
    });
    await OutboxDao(txn).enqueue(
      OutboxEntry(
        id: entryId(gesture.id),
        aggregateType: aggregateType,
        aggregateId: gesture.enrollmentId,
        operation: OutboxOperation.create,
        payload: jsonEncode(gesture.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
    return true;
  });
}
