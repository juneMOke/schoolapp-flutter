import 'package:school_app_flutter/core/database/projections/enrollment_suspension_sql.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_row.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_puller.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_gesture.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_period_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que la synchronisation fait des périodes locales : accusé d'un geste,
/// refus, descente du flux. L'accusé et le refus reprojettent l'appartenance
/// courante ; le flux, lui, laisse les membres au serveur.
///
/// **Le geste local gagne tant qu'il attend** : ni le flux ni un accusé
/// intermédiaire n'écrasent une inscription dont un geste est encore en file,
/// sans quoi un élève désactivé hors ligne réapparaîtrait avant l'envoi.
class EnrollmentSuspensionSyncDao {
  final Database _db;

  const EnrollmentSuspensionSyncDao(this._db);

  static const String table = EnrollmentSuspensionRow.table;

  /// Le geste est-il encore porté par une ligne locale ? Sinon (ligne retirée
  /// par une tombe, ou remplacée par la période d'une autre tablette), il n'a
  /// plus rien à envoyer.
  Future<bool> holds(SuspensionGesture gesture) async {
    final rows = await _db.query(
      table,
      columns: ['id'],
      where: switch (gesture.op) {
        SuspensionGestureOp.suspend => 'id = ?',
        SuspensionGestureOp.reactivate => 'reactivation_id = ?',
      },
      whereArgs: [gesture.id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Range l'état canonique rendu par le serveur pour l'inscription du geste.
  ///
  /// Tant qu'un autre geste de la même inscription attend, rien ne bouge : le
  /// dernier accusé apportera l'état final. Sinon, les lignes locales non
  /// accusées de l'inscription disparaissent au profit de la période du
  /// serveur — c'est ainsi qu'une désactivation absorbée par celle d'une autre
  /// tablette se recale dessus.
  Future<void> applyAck(
    SuspensionGesture gesture,
    SuspensionGestureAckDto ack, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    if (await _hasOtherPending(txn, gesture)) return;
    final period = ack.period;
    await txn.delete(
      table,
      where:
          'enrollment_id = ? AND sync_status != ?'
          '${period == null ? '' : ' AND id != ?'}',
      whereArgs: [
        gesture.enrollmentId,
        RecordSyncState.synced.dbValue,
        ?period?.id,
      ],
    );
    if (period != null) await _upsert(txn, period, schoolId, nowMs);
    await EnrollmentSuspensionSql.project(txn, [_targetOf(gesture)]);
  });

  /// Défait l'effet local d'un geste refusé (422, terminal).
  ///
  /// Une désactivation refusée n'a jamais existé : sa période s'efface et
  /// l'élève revient. Une réactivation refusée rouvre la période, marquée en
  /// échec pour que l'écran le dise — sauf si l'élève a été désactivé de
  /// nouveau entre-temps, où elle reste fermée.
  ///
  /// Le curseur du flux est effacé : pendant que le geste attendait, le pull a
  /// pu sauter la vérité du serveur sur cette inscription sans plus jamais la
  /// redescendre. Le prochain pull relit tout, et la rétablit.
  Future<void> undoRefused(
    SuspensionGesture gesture, {
    required String schoolId,
    required String code,
    required String reason,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.delete(
      SyncMetaDao.table,
      where: 'resource = ?',
      whereArgs: [EnrollmentSuspensionPuller.cursorKey(schoolId)],
    );
    switch (gesture.op) {
      case SuspensionGestureOp.suspend:
        await txn.delete(table, where: 'id = ?', whereArgs: [gesture.id]);
      case SuspensionGestureOp.reactivate:
        final reopened = !await _hasOpenPeriod(txn, gesture.enrollmentId);
        await txn.update(
          table,
          {
            if (reopened) ...{
              'reactivation_id': null,
              'reactivated_at': null,
              'reactivated_by': null,
            },
            'pending_op': null,
            'sync_status': RecordSyncState.failed.dbValue,
            'sync_error': reason,
            'sync_error_code': code,
            'updated_at': nowMs,
          },
          where: 'reactivation_id = ?',
          whereArgs: [gesture.id],
        );
    }
    await EnrollmentSuspensionSql.project(txn, [_targetOf(gesture)]);
  });

  static (String, String) _targetOf(SuspensionGesture g) =>
      (g.studentId, g.academicYearId);

  /// Applique une page du flux ; rend le nombre de lignes écrites.
  ///
  /// Ne touche pas aux membres de classe : le serveur projette lui-même ses
  /// périodes, et le flux des membres en apporte le statut.
  Future<int> applyPulled(
    List<SuspensionPeriodDto> periods, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (periods.isEmpty || schoolId.isEmpty) return 0;
    return _db.transaction((txn) async {
      var written = 0;
      for (final period in periods) {
        if (await _hasPendingGesture(txn, period.enrollmentId)) continue;
        await _upsert(txn, period, schoolId, nowMs);
        written++;
      }
      return written;
    });
  }

  /// Écrit [period] telle que le serveur la tient. Une période ouverte chasse
  /// d'abord les autres ouvertes de l'inscription : périmées, le flux les
  /// redescendra fermées.
  static Future<void> _upsert(
    DatabaseExecutor txn,
    SuspensionPeriodDto period,
    String schoolId,
    int nowMs,
  ) async {
    if (period.isOpen) {
      await txn.delete(
        table,
        where: 'enrollment_id = ? AND reactivated_at IS NULL AND id != ?',
        whereArgs: [period.enrollmentId, period.id],
      );
    }
    await txn.insert(
      table,
      period.toRow(schoolId: schoolId, nowMs: nowMs),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> _hasOpenPeriod(
    DatabaseExecutor txn,
    String enrollmentId,
  ) async => (await txn.query(
    table,
    columns: ['id'],
    where: 'enrollment_id = ? AND reactivated_at IS NULL',
    whereArgs: [enrollmentId],
    limit: 1,
  )).isNotEmpty;

  /// Un geste de l'inscription attend-il encore dans l'outbox ? Lu dans
  /// l'outbox et non sur la ligne : une entrée empoisonnée par le moteur
  /// laisserait sinon la ligne « en attente » et le flux la sauterait à jamais.
  static Future<bool> _hasPendingGesture(
    DatabaseExecutor txn,
    String enrollmentId,
  ) async => (await txn.query(
    OutboxDao.table,
    columns: ['id'],
    where: 'aggregate_type = ? AND aggregate_id = ? AND status = ?',
    whereArgs: [
      EnrollmentSuspensionWriteDao.aggregateType,
      enrollmentId,
      OutboxStatus.pending.dbValue,
    ],
    limit: 1,
  )).isNotEmpty;

  /// Un autre geste de la même inscription attend-il dans l'outbox ?
  static Future<bool> _hasOtherPending(
    DatabaseExecutor txn,
    SuspensionGesture gesture,
  ) async => (await txn.query(
    OutboxDao.table,
    columns: ['id'],
    where: 'aggregate_type = ? AND aggregate_id = ? AND status = ? AND id != ?',
    whereArgs: [
      EnrollmentSuspensionWriteDao.aggregateType,
      gesture.enrollmentId,
      OutboxStatus.pending.dbValue,
      EnrollmentSuspensionWriteDao.entryId(gesture.id),
    ],
    limit: 1,
  )).isNotEmpty;
}
