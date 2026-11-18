import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_correction_write_dao.dart'
    show kPaymentCorrectionAggregate;
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que la synchronisation fait d'une correction locale : accusé, refus,
/// disparition.
///
/// Aucune de ces écritures ne touche l'inscription, les créances ou la classe :
/// leur nouvel état vient du serveur, par la descente que le handler déclenche
/// après l'accusé. La ligne ne dit que ce qu'est devenu le geste.
class LevelCorrectionSyncDao {
  final Database _db;

  const LevelCorrectionSyncDao(this._db);

  static const String table = LevelCorrectionWriteDao.table;

  /// Le geste attend-il encore ? Sinon (ligne disparue, ou déjà jugée), il n'a
  /// plus rien à envoyer.
  Future<bool> holds(String gestureId) async => (await _db.query(
    table,
    columns: ['id'],
    where: 'id = ? AND sync_status = ?',
    whereArgs: [gestureId, RecordSyncState.pending.dbValue],
    limit: 1,
  )).isNotEmpty;

  /// Un versement de l'élève sur l'année — ou la correction d'un de ses
  /// versements — attend-il encore dans la file ?
  ///
  /// La correction de niveau doit partir **après** : le serveur juge le payé
  /// de l'élève, et un versement encore sur la tablette n'y est pas. Partie
  /// avant, elle serait jugée sur un payé incomplet, et le versement arrivé
  /// ensuite pourrait faire un trop-perçu (contrat du lot F, Q3). Le gel du
  /// guichet (D7) ne couvre que ce qui suit la correction, pas ce qui la
  /// précède.
  ///
  /// Une entrée sortie de la file (`SYNC_ERROR`) ne retient pas : son envoi est
  /// abandonné, et attendre la retiendrait sans fin.
  Future<bool> hasQueuedPayment({
    required String studentId,
    required String academicYearId,
  }) async => (await _db.rawQuery(
    '''
    SELECT 1 FROM ${OutboxDao.table} o
    JOIN payments p ON p.id = o.aggregate_id
    WHERE o.aggregate_type = 'PAYMENT' AND o.status = ?
      AND p.student_id = ?
      AND (p.academic_year_id = ? OR p.academic_year_id IS NULL)
    UNION ALL
    SELECT 1 FROM ${OutboxDao.table} o
    JOIN payment_corrections pc ON pc.id = o.aggregate_id
    JOIN payments p ON p.id = pc.payment_id
    WHERE o.aggregate_type = '$kPaymentCorrectionAggregate' AND o.status = ?
      AND p.student_id = ?
      AND (p.academic_year_id = ? OR p.academic_year_id IS NULL)
    LIMIT 1
    ''',
    [
      OutboxStatus.pending.dbValue,
      studentId,
      academicYearId,
      OutboxStatus.pending.dbValue,
      studentId,
      academicYearId,
    ],
  )).isNotEmpty;

  /// Le serveur a appliqué le geste (201), ou l'avait déjà appliqué (200).
  Future<void> markApplied(String gestureId, {required int nowMs}) =>
      _db.update(
        table,
        {
          'sync_status': RecordSyncState.synced.dbValue,
          'sync_error': null,
          'sync_error_code': null,
          'acked_at': nowMs,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [gestureId],
      );

  /// Refus terminal (422) : le code reste sur la ligne pour que l'écran le
  /// traduise. Rien d'autre n'est à défaire, le geste n'ayant rien changé.
  Future<void> markRefused(
    String gestureId, {
    required String code,
    required String reason,
    required int nowMs,
  }) => _db.update(
    table,
    {
      'sync_status': RecordSyncState.failed.dbValue,
      'sync_error': reason,
      'sync_error_code': code,
      'updated_at': nowMs,
    },
    where: 'id = ?',
    whereArgs: [gestureId],
  );

  /// Une correction accusée attend-elle encore sa descente ?
  Future<bool> hasUnsettled() async => (await _db.query(
    table,
    columns: ['id'],
    where: 'sync_status = ? AND settled_at IS NULL',
    whereArgs: [RecordSyncState.synced.dbValue],
    limit: 1,
  )).isNotEmpty;

  /// Une descente partie à [pulledFromMs] (horloge locale) a ramené le nouvel
  /// état du serveur : les corrections accusées **avant** son départ sont
  /// descendues. Une correction accusée pendant la descente attend la
  /// suivante — la réponse a pu être composée avant son accusé.
  ///
  /// Renvoie les inscriptions concernées.
  Future<Set<String>> markSettled({
    required int pulledFromMs,
    required int nowMs,
  }) => _db.transaction((txn) async {
    const where = 'sync_status = ? AND settled_at IS NULL AND acked_at <= ?';
    final args = [RecordSyncState.synced.dbValue, pulledFromMs];
    final rows = await txn.query(
      table,
      columns: ['enrollment_id'],
      where: where,
      whereArgs: args,
    );
    if (rows.isEmpty) return const <String>{};
    await txn.update(
      table,
      {'settled_at': nowMs, 'updated_at': nowMs},
      where: where,
      whereArgs: args,
    );
    return {for (final r in rows) r['enrollment_id']! as String};
  });

  /// L'inscription a été purgée au serveur (410) : le geste n'a plus d'objet.
  Future<void> drop(String gestureId) =>
      _db.delete(table, where: 'id = ?', whereArgs: [gestureId]);
}
