import 'dart:typed_data';

import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_blob_ids.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

/// Les octets des photos dans leur magasin chiffré : les gestes en attente et
/// les copies d'affichage. Ne connaît pas la table ; c'est l'appelant qui dit
/// quelle copie est à jour.
///
/// Toutes les écritures passent par l'attente puis la promotion du magasin :
/// une panne entre les deux laisse l'ancienne copie intacte.
class StudentPhotoBlobs {
  final EncryptedBlobStore _store;

  const StudentPhotoBlobs(this._store);

  Future<bool> _write(String id, Uint8List bytes) async {
    final stored = await _store.stage(id: id, bytes: bytes);
    if (stored == null || !await _store.commit(id)) {
      await _store.discard(id);
      return false;
    }
    return true;
  }

  /// Scelle les octets d'un geste ; `false` si rien n'a pu être écrit.
  Future<bool> writePending(String studentId, String sha256, Uint8List bytes) =>
      _write(StudentPhotoBlobIds.pending(studentId, sha256), bytes);

  Future<BlobRead> readPending(String studentId, String sha256) =>
      _store.read(StudentPhotoBlobIds.pending(studentId, sha256));

  Future<void> deletePending(String studentId, String sha256) =>
      _store.delete(StudentPhotoBlobIds.pending(studentId, sha256));

  Future<bool> writeCache(
    String studentId,
    StudentPhotoSize size,
    Uint8List bytes,
  ) => _write(StudentPhotoBlobIds.cached(studentId, size), bytes);

  Future<BlobRead> readCache(String studentId, StudentPhotoSize size) =>
      _store.read(StudentPhotoBlobIds.cached(studentId, size));

  /// Efface les copies d'affichage de l'élève, toutes tailles.
  Future<void> deleteCaches(String studentId) async {
    for (final size in StudentPhotoSize.values) {
      await _store.delete(StudentPhotoBlobIds.cached(studentId, size));
    }
  }
}
