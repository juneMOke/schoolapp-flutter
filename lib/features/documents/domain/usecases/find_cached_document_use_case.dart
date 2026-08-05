import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Répond à une seule question : **cette pièce-là est-elle sur cette
/// tablette ?**
///
/// Sert à choisir le geste avant qu'on l'offre — ressortir une copie locale ou
/// demander une production au serveur. Poser la question après le clic
/// donnerait un bouton qui change d'avis en cours de route.
///
/// Le numéro n'étant unique que **par école**, la recherche est scopée par
/// [CurrentUserContext] : sans école courante, on ne cherche rien plutôt que de
/// rendre la pièce d'un autre établissement.
///
/// Ne remonte jamais d'erreur : ne pas savoir revient à ne pas avoir.
class FindCachedDocumentUseCase {
  final EditiqueCacheDao _dao;
  final CurrentUserContext _currentUser;

  const FindCachedDocumentUseCase(this._dao, this._currentUser);

  Future<EditiqueCacheEntry?> call({
    String? documentId,
    String? documentNumber,
  }) async {
    try {
      if (documentId != null && documentId.isNotEmpty) {
        final byId = await _dao.findByDocumentId(documentId);
        if (byId != null) return _heldOnly(byId);
      }

      if (documentNumber == null || documentNumber.trim().isEmpty) return null;
      final schoolId = _currentUser.schoolId;
      if (schoolId == null || schoolId.isEmpty) return null;

      final byNumber = await _dao.findByDocumentNumber(
        schoolId: schoolId,
        documentNumber: documentNumber,
      );
      return byNumber == null ? null : _heldOnly(byNumber);
    } catch (_) {
      return null;
    }
  }

  /// La question posée est « est-elle SUR cette tablette ? », pas « existe-t-elle
  /// quelque part ? ». Depuis le delta de synchronisation, l'index sait répondre
  /// à la seconde — et confondre les deux ferait proposer de ressortir une pièce
  /// dont les octets ne sont pas là.
  EditiqueCacheEntry? _heldOnly(EditiqueCacheEntry entry) {
    return entry.hasBytes ? entry : null;
  }
}
