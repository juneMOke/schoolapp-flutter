import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Pose, dès l'accusé d'une correction, l'annulation du reçu d'origine dans le
/// cache des pièces (R8) — sans attendre le pull des pièces.
///
/// Sans elle, la fiche d'un versement corrigé montrait encore son reçu comme
/// valide jusqu'au prochain cycle : le numéro non barré, et « Télécharger le
/// reçu » qui le restituait sans motif.
///
/// ⚠️ **Deux bases.** Le cache vit dans `device.db` ; l'accusé s'applique dans
/// la base de l'école. Cette écriture vient donc APRÈS la transaction de
/// l'accusé, et elle ne la défait jamais : best-effort, un échec est muet et le
/// pull des pièces rattrapera.
class CancelledReceiptRecorder {
  final EditiqueCacheDao _cache;
  final EditiqueCacheAccess _access;
  final CurrentUserContext _currentUser;
  final IdGenerator _ids;

  const CancelledReceiptRecorder({
    required EditiqueCacheDao cache,
    required EditiqueCacheAccess access,
    required CurrentUserContext currentUser,
    required IdGenerator ids,
  }) : _cache = cache,
       _access = access,
       _currentUser = currentUser,
       _ids = ids;

  Future<void> record({
    required String? documentId,
    required String? documentNumber,
    required int cancelledAt,
    String? reason,
  }) async {
    try {
      final schoolId = _currentUser.schoolId;
      if (schoolId == null || schoolId.isEmpty) return;
      if (!await _access.isEntitled()) return;
      final id = _text(documentId);
      final number = _text(documentNumber);
      if (id == null && number == null) return;
      // `upsert` garde tout ce qu'il sait déjà (octets, élève, année) et ne
      // perd jamais une annulation : on ne lui apprend que celle-ci.
      await _cache.upsert(
        EditiqueCacheEntry(
          id: _ids.newId(),
          documentId: id,
          documentNumber: number,
          docType: 'RC',
          schoolId: schoolId,
          ownerUid: _currentUser.uid ?? '',
          sizeBytes: 0,
          cancelledAt: cancelledAt,
          cancellationReason: reason,
          createdAt: cancelledAt,
          lastAccessedAt: cancelledAt,
        ),
      );
    } catch (_) {
      // Best-effort : le pull des pièces posera la même annulation.
    }
  }

  static String? _text(String? value) {
    final text = value?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }
}
