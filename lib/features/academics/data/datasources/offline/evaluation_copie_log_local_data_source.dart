import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/copie_log_row.dart';

/// Accès sqflite au journal des copies (`evaluation_copie_log`), **insert
/// seul** : une diffusion ne se modifie ni ne s'efface.
class EvaluationCopieLogLocalDataSource {
  final Database _db;

  const EvaluationCopieLogLocalDataSource(this._db);

  static const String _table = 'evaluation_copie_log';

  /// Journal d'une évaluation, la plus récente d'abord.
  Future<List<CopieLogRow>> getForEvaluation(String evaluationId) async {
    final rows = await _db.query(
      _table,
      where: 'evaluation_id = ?',
      whereArgs: [evaluationId],
      orderBy: 'occurred_at DESC, id DESC',
    );
    return rows.map(CopieLogRow.fromMap).toList(growable: false);
  }

  /// Ajoute une diffusion et, si fournie, son entrée d'outbox, dans une
  /// transaction. Un rejeu du même id ne duplique rien.
  Future<void> insertWithOutbox(CopieLogRow row, {OutboxEntry? outboxEntry}) =>
      _db.transaction((txn) async {
        await txn.insert(
          _table,
          row.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (outboxEntry != null) await OutboxDao(txn).enqueue(outboxEntry);
      });

  Future<void> markSynced(String id) => _setStatus(id, SyncState.synced);

  Future<void> markSyncError(String id) => _setStatus(id, SyncState.syncError);

  /// Applique les diffusions descendues du serveur sur [executor] : une ligne
  /// inconnue est insérée `SYNCED`, une ligne locale est marquée `SYNCED` —
  /// le serveur la connaît, elle n'a plus à partir.
  Future<void> applyPulled(
    DatabaseExecutor executor,
    List<CopieLogRow> rows,
  ) async {
    for (final row in rows) {
      // Retour d'`insert` en mode `ignore` variable selon la plateforme :
      // l'existence se lit, elle ne se déduit pas.
      final known = await executor.query(
        _table,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [row.id],
        limit: 1,
      );
      if (known.isEmpty) {
        await executor.insert(_table, {
          ...row.toMap(),
          'sync_status': SyncState.synced.dbValue,
        });
      } else {
        await executor.update(
          _table,
          {'sync_status': SyncState.synced.dbValue},
          where: 'id = ?',
          whereArgs: [row.id],
        );
      }
    }
  }

  Future<void> _setStatus(String id, SyncState state) async {
    await _db.update(
      _table,
      {'sync_status': state.dbValue},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
