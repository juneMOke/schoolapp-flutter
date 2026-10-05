import 'dart:typed_data';

import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les fichiers des ressources-documents dans leur magasin chiffré, sous l'id
/// de la ressource : à envoyer tant qu'elle attend, copie de lecture ensuite
/// (une ressource ne change jamais de contenu).
///
/// Les écritures et le ménage des orphelins passent **l'un après l'autre**
/// ([guarded]) : un fichier tout juste scellé dont la ligne n'est pas encore
/// insérée serait sinon pris pour un orphelin et effacé.
class ProgrammeBlobs {
  final EncryptedBlobStore _store;
  final DatabaseExecutor _db;
  Future<void> _tail = Future.value();

  ProgrammeBlobs({
    required EncryptedBlobStore store,
    required DatabaseExecutor db,
  }) : _store = store,
       _db = db;

  /// Exécute [body] seul, à la suite des écritures et ménages en cours.
  Future<T> guarded<T>(Future<T> Function() body) {
    final run = _tail.then((_) => body());
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// Scelle [bytes] ; `false` si rien n'a pu être écrit. À appeler dans
  /// [guarded], avec l'insertion de la ligne.
  Future<bool> write(String ressourceId, Uint8List bytes) async {
    final stored = await _store.stage(id: ressourceId, bytes: bytes);
    if (stored == null || !await _store.commit(ressourceId)) {
      await _store.discard(ressourceId);
      return false;
    }
    return true;
  }

  Future<BlobRead> read(String ressourceId) => _store.read(ressourceId);

  Future<void> delete(String ressourceId) async {
    await _store.delete(ressourceId);
  }

  /// Efface les fichiers qu'aucune ressource-document ne désigne plus
  /// (chapitre retiré, cours évincé, ressource retirée ailleurs).
  Future<int> reclaimOrphans() => guarded(() async {
    final rows = await _db.query(
      ProgrammeTables.ressource,
      columns: ['id'],
      where: 'type = ?',
      whereArgs: [RessourceType.document.wireValue],
    );
    return _store.reclaimOrphans(
      indexedIds: {for (final row in rows) row['id'] as String},
    );
  });
}
