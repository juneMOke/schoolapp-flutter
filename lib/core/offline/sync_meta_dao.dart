import 'package:sqflite_common/sqlite_api.dart';

/// Curseurs de pull par ressource + horodatage de dernière synchro réussie
/// (fraîcheur ADR-002). Table `sync_meta(resource PK, cursor, synced_at)`.
class SyncMetaDao {
  final DatabaseExecutor _db;

  const SyncMetaDao(this._db);

  static const String table = 'sync_meta';

  /// Curseur de pull d'une ressource (null si jamais synchronisée). Jeton
  /// **opaque** du serveur, stocké verbatim et re-renvoyé au prochain pull —
  /// jamais interprété. Sa forme dépend de la ressource : ISO-8601
  /// (`max(updated_at)`) pour les deltas timestampés (classe/présence/finance),
  /// **jeton keyset base64url** (`nextCursor`/`nextWatermark`) pour l'inscription
  /// (ADR-008/009).
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

  /// Avance le curseur (jeton serveur opaque, cf. [getCursor]) et l'horodatage
  /// de fraîcheur locale (epoch ms) — upsert.
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

  /// Supprime le curseur d'une ressource — pour une ressource **scopée à une
  /// entité évincée** (ex. cours réaffecté à un autre prof) dont le cycle de
  /// vie s'arrête là : sans ça, une entité qui redeviendrait valide plus tard
  /// (ex. réaffectée en retour) reprendrait un curseur périmé au lieu de
  /// rebootstraper, et perdrait silencieusement tout ce qui existait avant
  /// l'éviction. No-op si la ressource n'a pas de curseur.
  Future<void> deleteCursor(String resource) async {
    await _db.delete(table, where: 'resource = ?', whereArgs: [resource]);
  }

  /// Rembobine au bootstrap une ressource **et toutes ses variantes scopées**
  /// (`<prefix>`, `<prefix>@…`, `<prefix>:…`).
  ///
  /// Une ressource peut porter plusieurs curseurs — un par école, un par
  /// enseignant — et les effacer un par un supposerait de savoir lesquels
  /// existent. Quand la donnée locale d'une ressource est détruite, ses curseurs
  /// doivent l'être **tous** : un curseur laissé en avance ferait répondre
  /// « rien de neuf » au cycle suivant, sur une base vide, jusqu'à la prochaine
  /// écriture serveur.
  Future<void> deleteCursorsOf(String resourcePrefix) async {
    await _db.delete(
      table,
      where: 'resource = ? OR resource LIKE ? OR resource LIKE ?',
      whereArgs: [resourcePrefix, '$resourcePrefix@%', '$resourcePrefix:%'],
    );
  }
}
