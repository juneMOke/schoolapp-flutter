import 'dart:typed_data';

import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Magasin de fichiers en mémoire : mêmes gestes que [ProgrammeBlobs], sans
/// chiffrement ni disque.
class FakeProgrammeBlobs implements ProgrammeBlobs {
  final Map<String, Uint8List> files = {};
  int reclaims = 0;
  bool failWrites = false;

  @override
  Future<T> guarded<T>(Future<T> Function() body) => body();

  @override
  Future<bool> write(String ressourceId, Uint8List bytes) async {
    if (failWrites) return false;
    files[ressourceId] = bytes;
    return true;
  }

  @override
  Future<BlobRead> read(String ressourceId) async {
    final bytes = files[ressourceId];
    return bytes == null
        ? const BlobGone()
        : BlobFound(LoadedBlob(bytes: bytes, sha256Hex: 'sha'));
  }

  @override
  Future<void> delete(String ressourceId) async => files.remove(ressourceId);

  @override
  Future<void> deleteAll(Iterable<String> ressourceIds) async {
    for (final id in ressourceIds) {
      files.remove(id);
    }
  }

  @override
  Future<int> reclaimOrphans() async {
    reclaims++;
    return 0;
  }
}

/// Les entrées d'outbox, par identifiant.
Future<Map<String, OutboxEntry>> outboxById(Database db) async => {
  for (final row in await db.query('outbox'))
    row['id'] as String: OutboxEntry.fromMap(row),
};
