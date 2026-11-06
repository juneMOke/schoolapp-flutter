import 'package:school_app_flutter/core/offline/record_sync_state.dart';
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

  /// L'inscription a été purgée au serveur (410) : le geste n'a plus d'objet.
  Future<void> drop(String gestureId) =>
      _db.delete(table, where: 'id = ?', whereArgs: [gestureId]);
}
