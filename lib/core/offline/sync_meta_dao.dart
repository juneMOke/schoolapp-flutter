import 'package:sqflite_common/sqlite_api.dart';

/// Curseurs de pull par ressource + horodatage de dernière synchro réussie
/// (fraîcheur ADR-002). Table `sync_meta(resource PK, cursor, synced_at)`.
class SyncMetaDao {
  final DatabaseExecutor _db;

  const SyncMetaDao(this._db);

  static const String table = 'sync_meta';

  /// Curseur `updatedSince` d'une ressource (null si jamais synchronisée).
  Future<int?> getCursor(String resource) async {
    final rows = await _db.query(
      table,
      columns: ['cursor'],
      where: 'resource = ?',
      whereArgs: [resource],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['cursor'] as int?;
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

  /// Avance le curseur et l'horodatage de fraîcheur (upsert).
  Future<void> setCursor(
    String resource, {
    required int? cursor,
    required int syncedAt,
  }) async {
    await _db.insert(table, {
      'resource': resource,
      'cursor': cursor,
      'synced_at': syncedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
