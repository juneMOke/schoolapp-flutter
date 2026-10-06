import 'dart:typed_data';

import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le magasin chiffré de l'école [schoolId] (son répertoire à elle).
typedef ProgrammeStoreFor = EncryptedBlobStore Function(String? schoolId);

/// Les fichiers des ressources-documents dans leur magasin chiffré, sous l'id
/// de la ressource : à envoyer tant qu'elle attend, copie de lecture ensuite
/// (une ressource ne change jamais de contenu).
///
/// **Un magasin par école** : la base ouverte est celle de l'école de la
/// session, et le ménage des orphelins ne connaît que ses ressources — sur un
/// magasin commun, il effacerait les documents en attente d'une autre école
/// du poste.
///
/// Les écritures et le ménage passent **l'un après l'autre** ([guarded]) :
/// un fichier tout juste scellé dont la ligne n'est pas encore insérée serait
/// sinon pris pour un orphelin et effacé.
class ProgrammeBlobs {
  final ProgrammeStoreFor _storeFor;
  final String? Function() _schoolId;
  final DatabaseExecutor _db;
  final Map<String?, EncryptedBlobStore> _stores = {};
  Future<void> _tail = Future.value();

  ProgrammeBlobs({
    required ProgrammeStoreFor storeFor,
    required String? Function() schoolId,
    required DatabaseExecutor db,
  }) : _storeFor = storeFor,
       _schoolId = schoolId,
       _db = db;

  EncryptedBlobStore get _store {
    final school = _schoolId();
    return _stores.putIfAbsent(school, () => _storeFor(school));
  }

  /// Exécute [body] seul, à la suite des écritures et ménages en cours.
  Future<T> guarded<T>(Future<T> Function() body) {
    final run = _tail.then((_) => body());
    _tail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// Scelle [bytes] ; `false` si rien n'a pu être écrit. À appeler dans
  /// [guarded], avec l'insertion de la ligne.
  Future<bool> write(String ressourceId, Uint8List bytes) async {
    final store = _store;
    final stored = await store.stage(id: ressourceId, bytes: bytes);
    if (stored == null || !await store.commit(ressourceId)) {
      await store.discard(ressourceId);
      return false;
    }
    return true;
  }

  Future<BlobRead> read(String ressourceId) => _store.read(ressourceId);

  Future<void> delete(String ressourceId) async {
    await _store.delete(ressourceId);
  }

  /// Efface les fichiers de [ressourceIds] (leurs lignes viennent de partir).
  Future<void> deleteAll(Iterable<String> ressourceIds) async {
    for (final id in ressourceIds) {
      await delete(id);
    }
  }

  /// Efface les fichiers de l'école qu'aucune ressource-document ne désigne
  /// plus (chapitre ou cours disparu côté serveur, ressource retirée
  /// ailleurs).
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
