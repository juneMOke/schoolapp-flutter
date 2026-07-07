import 'package:sqflite_common/sqlite_api.dart';

/// Curseurs de pull par ressource + horodatage de dernière synchro réussie
/// (fraîcheur ADR-002). Table `sync_meta(resource PK, cursor, synced_at)`.
class SyncMetaDao {
  final DatabaseExecutor _db;

  const SyncMetaDao(this._db);

  static const String table = 'sync_meta';

  /// Curseur `updatedSince` d'une ressource (null si jamais synchronisée).
  /// Jeton opaque du serveur — **ISO-8601** (`max(updated_at)` renvoyé), stocké
  /// verbatim et re-renvoyé au prochain pull. Ne jamais l'interpréter en entier.
  Future<String?> getCursor(String resource) async {
    final rows = await _db.query(
      table,
      columns: ['cursor'],
      where: 'resource = ?',
      whereArgs: [resource],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['cursor'] as String?;
  }

  /// Epoch ms de la dernière synchro réussie (pour l'affichage de fraîcheur).
  Future<int?> getSyncedAt(String resource) async {
    final rows = await _db.query(
      table,
      columns: ['synced_at'],
      where: 'resource = ?',
      whereArgs: [resource],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['synced_at'] as int?;
  }

  /// Avance le curseur (ISO-8601, jeton serveur opaque) et l'horodatage de
  /// fraîcheur locale (epoch ms) — upsert.
  Future<void> setCursor(
    String resource, {
    required String? cursor,
    required int syncedAt,
  }) async {
    await _db.insert(table, {
      'resource': resource,
      'cursor': cursor,
      'synced_at': syncedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
