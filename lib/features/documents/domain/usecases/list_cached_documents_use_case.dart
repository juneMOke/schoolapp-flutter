import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Tout ce que **cette tablette** sait des pièces d'un élève : celles dont elle
/// détient une copie scellée, celles que l'école a retirées, et celles dont le
/// delta lui a seulement appris l'existence.
///
/// C'est la seule source qui dit ce qui est consultable hors ligne. La nuance
/// est essentielle : le barème du catalogue dit ce qu'une pièce **autorise**
/// (« restitution offline ✅ »), pas ce qui est **déjà là**. Promettre
/// « Consulter » sur un type plutôt que sur un fait produirait un bouton qui
/// échoue une fois sur deux.
///
/// Mais c'est une **lecture**, pas un arbitre : elle rend ce qu'elle sait et
/// laisse le résolveur d'actions choisir le geste. Trier ici avait paru
/// prudent ; ça revenait à décider deux fois, et la seconde décision, aveugle
/// au contexte de la première, se trompait — une pièce de remplacement
/// disparaissait, et sa devancière annulée s'annonçait comme la dernière
/// nouvelle de ce type.
///
/// Distincte de la trace locale de `generated_documents`, qui n'enregistre que
/// ce que cette tablette a elle-même produit et n'a jamais d'octets à servir.
///
/// Ne remonte jamais d'erreur : une lecture qui échoue rend une liste vide, et
/// la ligne retombe sur « Émettre » — ce qui ne coûte rien sur une pièce
/// idempotente.
///
/// La garde de profil (RG-012-4) est vérifiée **ici aussi**, et pas seulement à
/// l'écriture : l'effacement d'ouverture de session traite le cas ordinaire,
/// mais entre deux ouvertures — un rôle rétrogradé par le serveur, une session
/// déjà ouverte — l'index survivrait à la perte du droit. Un profil sans droit
/// ne doit rien voir, même de ce qui reste sur le disque.
class ListCachedDocumentsUseCase {
  final EditiqueCacheDao _dao;
  final CurrentUserContext _currentUser;
  final EditiqueCacheAccess _access;

  const ListCachedDocumentsUseCase(this._dao, this._currentUser, this._access);

  Future<List<EditiqueCacheEntry>> call({
    required String studentId,
    String? academicYearId,
  }) async {
    final schoolId = _currentUser.schoolId;
    // La portée de lecture est l'école : sans elle, on ne lit rien plutôt que
    // de lire tout.
    if (schoolId == null || schoolId.isEmpty) return const [];
    if (studentId.trim().isEmpty) return const [];

    try {
      if (!await _access.isEntitled()) return const [];

      // **Aucun filtre.** Ce que l'index sait des pièces de cet élève est rendu
      // tel quel, dans l'ordre du serveur — la plus récemment émise d'abord.
      //
      // Un filtre a bien vécu ici : il ne gardait que les pièces détenues, pour
      // empêcher « Consulter » de s'allumer sur des octets absents. Cette garde
      // existe désormais là où la décision se prend (`_findCached` du
      // résolveur, qui exige `hasBytes && !isCancelled`), et la doubler ici
      // coûtait plus qu'elle ne protégeait : elle **cachait au résolveur les
      // pièces de remplacement**. Annuler puis réémettre est le flux nominal —
      // la migration back V74 est bâtie pour lui — et les deux lignes
      // descendent par le delta sans octets. En taisant la remplaçante, la
      // ligne annonçait « Pièce annulée » alors qu'une pièce en vigueur
      // existait, et le disait d'autant plus longtemps qu'on était hors ligne.
      //
      // Une lecture ne doit pas trancher à la place de qui décide : elle rend
      // ce qu'elle sait, le résolveur choisit le geste.
      return _dao.listForStudent(
        schoolId: schoolId,
        studentId: studentId,
        academicYearId: academicYearId,
      );
    } catch (_) {
      return const [];
    }
  }
}
