import 'dart:convert';

import 'package:school_app_flutter/core/database/projections/enrollment_level_correction_sql.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_in_force_sql.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Issue d'une demande de correction, vue de la tablette.
enum LevelCorrectionRecordOutcome {
  /// Le geste est posé, et part par l'outbox.
  recorded,

  /// Une correction de la même inscription attend déjà : rien n'est écrit.
  alreadyPending,

  /// L'élève a un versement en vigueur sur l'année : le serveur refuserait en
  /// `LEVEL_CORRECTION_HAS_PAYMENTS` (premier temps). Rien n'est écrit.
  hasPayments,
}

/// Écriture d'une correction de niveau — **la ligne et son entrée d'outbox dans
/// une seule transaction** : le geste existe en entier ou pas du tout.
///
/// Une entrée par geste (`ENROLLMENT_LEVEL_CORRECTION:<id du geste>`), jamais
/// remplacée, rattachée à l'inscription (`aggregate_id`) pour que le handler
/// garde l'ordre des gestes d'un même élève.
class LevelCorrectionWriteDao {
  final Database _db;

  const LevelCorrectionWriteDao(this._db);

  static const String table = EnrollmentLevelCorrectionSql.table;
  static const String aggregateType =
      EnrollmentLevelCorrectionSql.aggregateType;

  static String entryId(String gestureId) => '$aggregateType:$gestureId';

  /// Pose [gesture], sauf si une correction de la même inscription attend déjà
  /// (la seconde partirait sur un niveau de départ périmé et tomberait en
  /// `STALE_LEVEL`) ou si l'élève a déjà un versement en vigueur sur l'année.
  ///
  /// Le second contrôle ne remplace pas la garde du serveur : un versement pris
  /// sur une autre tablette n'est pas encore ici. Il épargne seulement au
  /// guichet un geste dont le refus est certain.
  Future<LevelCorrectionRecordOutcome> record(
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
    if (pending.isNotEmpty) return LevelCorrectionRecordOutcome.alreadyPending;
    final payments = await txn.rawQuery(
      'SELECT 1 FROM payments p '
      'WHERE p.student_id = ? AND p.academic_year_id = ? '
      'AND ${PaymentInForceSql.inForce('p')} LIMIT 1',
      [gesture.studentId, gesture.academicYearId],
    );
    if (payments.isNotEmpty) return LevelCorrectionRecordOutcome.hasPayments;
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
    return LevelCorrectionRecordOutcome.recorded;
  });
}
