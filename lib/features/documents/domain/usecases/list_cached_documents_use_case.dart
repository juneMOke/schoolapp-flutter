import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Ce que **cette tablette** sait des pièces d'un élève quand ce savoir change
/// le geste à lui offrir : une copie scellée qu'elle détient, ou une pièce que
/// l'école a retirée.
///
/// C'est la seule source qui dit ce qui est consultable hors ligne. La nuance
/// est essentielle : le barème du catalogue dit ce qu'une pièce **autorise**
/// (« restitution offline ✅ »), pas ce qui est **déjà là**. Promettre
/// « Consulter » sur un type plutôt que sur un fait produirait un bouton qui
/// échoue une fois sur deux.
///
/// Une pièce annulée en fait partie, et n'en sort jamais : elle ne se consulte
/// pas, mais la taire ferait retomber la ligne sur « Émettre » sans dire
/// pourquoi la pièce d'hier n'a plus cours — or c'est exactement ce qu'un
/// guichet doit pouvoir expliquer à la famille qui la lui présente.
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

      final indexed = await _dao.listForStudent(
        schoolId: schoolId,
        studentId: studentId,
        academicYearId: academicYearId,
      );
      // **Ce qui change le geste à offrir**, et rien d'autre. L'index décrit
      // trois sortes de lignes depuis le delta de synchronisation, et deux
      // seulement méritent de remonter :
      //
      // - **détenue** — la tablette a les octets. Elle se consulte ;
      // - **annulée** — l'école a retiré la pièce. Elle ne se consulte pas au
      //   catalogue, mais elle doit remonter quand même : c'est ce qui permet
      //   d'afficher le motif plutôt que de laisser la ligne retomber en
      //   silence sur « Émettre », comme si de rien n'était. Le motif vit dans
      //   l'index, donc il survit même à l'éviction des octets ;
      // - **connue seulement** — la pièce existe ailleurs, la tablette n'en a
      //   rien. Rendre celle-là ferait allumer « Consulter » sur une pièce
      //   absente : un bouton qui échoue à tous les coups hors ligne,
      //   c'est-à-dire précisément là où il est censé servir.
      //
      // Le critère n'est donc PAS « pas d'octets ⇒ masquer ». Les deux axes
      // sont indépendants, et une pièce annulée peut être dans l'un ou l'autre
      // état d'octets.
      return indexed
          .where((entry) => entry.hasBytes || entry.isCancelled)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
