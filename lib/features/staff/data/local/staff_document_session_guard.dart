import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_sync_dao.dart';

/// Ce qu'une ouverture de session décide des octets des pièces du personnel.
///
/// Un compte sans `hr.document.read` ne doit pas trouver sur la tablette les
/// pièces d'identité et les diplômes qu'un autre y a ouverts : leurs copies
/// sont effacées : celles **accusées** — le serveur les garde et les rendra à
/// qui a le droit — et celles **refusées**, qui ne partiront jamais. Une pièce
/// encore en attente d'envoi n'existe que là : l'effacer la perdrait, elle
/// reste chiffrée jusqu'à son envoi.
///
/// Des permissions inconnues (compte jamais revu par le serveur) n'effacent
/// rien : on ne sait pas.
///
/// Ne lève jamais : une hygiène de disque ne fait pas échouer une session.
class StaffDocumentSessionGuard {
  final EncryptedBlobStore _store;
  final StaffDocumentSyncDao _documents;
  final AuthLocalDao _authLocalDao;

  const StaffDocumentSessionGuard({
    required EncryptedBlobStore store,
    required StaffDocumentSyncDao documents,
    required AuthLocalDao authLocalDao,
  }) : _store = store,
       _documents = documents,
       _authLocalDao = authLocalDao;

  /// Rend le nombre de pièces réglées dont il ne reste plus de copie.
  Future<int> onSessionOpened() async {
    try {
      final user = await _authLocalDao.getSessionUser();
      final permissions = user?.permissions;
      if (permissions == null) return 0;
      if (permissions.contains(Perm.hrDocumentRead.wire)) return 0;
      var removed = 0;
      for (final id in await _documents.settledIds()) {
        if (await _store.delete(id)) removed++;
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }
}
