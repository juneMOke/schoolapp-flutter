import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Répond à une seule question : **que sait cette tablette de cette pièce-là,
/// qui puisse changer le geste à offrir ?**
///
/// Sert à choisir ce geste avant qu'on l'offre — ressortir une copie locale,
/// demander une production au serveur, ou dire que la pièce a été retirée.
/// Poser la question après le clic donnerait un bouton qui change d'avis en
/// cours de route.
///
/// Le numéro n'étant unique que **par école**, la recherche est scopée par
/// [CurrentUserContext] : sans école courante, on ne cherche rien plutôt que de
/// rendre la pièce d'un autre établissement.
///
/// Ne remonte jamais d'erreur : ne pas savoir revient à ne pas avoir.
///
/// La garde de profil (RG-012-4) est vérifiée **ici aussi**, et pas seulement à
/// l'écriture : l'effacement d'ouverture de session traite le cas ordinaire,
/// mais entre deux ouvertures — un rôle rétrogradé par le serveur, une session
/// déjà ouverte — l'index survivrait à la perte du droit. Pour un profil sans
/// droit, ne pas avoir le droit revient à ne pas avoir la pièce.
class FindCachedDocumentUseCase {
  final EditiqueCacheDao _dao;
  final CurrentUserContext _currentUser;
  final EditiqueCacheAccess _access;

  const FindCachedDocumentUseCase(this._dao, this._currentUser, this._access);

  Future<EditiqueCacheEntry?> call({
    String? documentId,
    String? documentNumber,
  }) async {
    try {
      if (!await _access.isEntitled()) return null;

      if (documentId != null && documentId.isNotEmpty) {
        final byId = await _dao.findByDocumentId(documentId);
        if (byId != null) return _decisiveOnly(byId);
      }

      if (documentNumber == null || documentNumber.trim().isEmpty) return null;
      final schoolId = _currentUser.schoolId;
      if (schoolId == null || schoolId.isEmpty) return null;

      final byNumber = await _dao.findByDocumentNumber(
        schoolId: schoolId,
        documentNumber: documentNumber,
      );
      return byNumber == null ? null : _decisiveOnly(byNumber);
    } catch (_) {
      return null;
    }
  }

  /// Ne rend que ce qui **change le geste** : une pièce détenue, ou une pièce
  /// retirée par l'école.
  ///
  /// La question n'est pas « existe-t-elle quelque part ? » — depuis le delta
  /// de synchronisation, l'index sait répondre à celle-là, et les confondre
  /// ferait proposer de ressortir une pièce dont les octets ne sont pas là.
  ///
  /// Une pièce annulée remonte même sans octets : c'est ce qui permet à
  /// l'appelant d'afficher pourquoi elle n'a plus cours au lieu de la traiter
  /// comme absente. À lui, en revanche, de ne pas la tenir pour consultable —
  /// et de vérifier `hasBytes` avant d'en promettre les octets, que l'éviction
  /// a pu emporter.
  EditiqueCacheEntry? _decisiveOnly(EditiqueCacheEntry entry) {
    return (entry.hasBytes || entry.isCancelled) ? entry : null;
  }
}
