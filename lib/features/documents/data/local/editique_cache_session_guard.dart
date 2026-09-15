import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/data/repositories/offline/editique_document_pull_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';

/// Ce qu'une ouverture de session décide du cache de pièces scellées
/// (ADR-012 D-7, RG-012-4).
///
/// ## Pourquoi à l'ouverture, et pas à la fermeture
///
/// Effacer à chaque déconnexion viderait le cache tous les soirs sur une
/// tablette partagée — la disponibilité hors ligne, seule raison d'être de ce
/// cache, disparaîtrait avec. À l'ouverture, au contraire, le rôle de celui qui
/// arrive est connu. Les octets, eux, sont chiffrés entre-temps.
///
/// ## Ce qui déclenche un effacement
///
/// **Une seule situation : le profil n'a pas droit au cache** (RG-012-4) — un
/// enseignant ouvre une session sur une tablette d'administration, et ce
/// qu'elle contenait ne doit pas rester à sa portée.
///
/// ## Ce qui n'en déclenche plus : le changement d'école
///
/// Jusqu'à l'éclatement par école, une école différente de la précédente
/// effaçait tout (RG-012-21). Les écoles d'un poste coexistent désormais
/// (MULTI_ECOLE_PLAN.md §10.1) : un chef qui bascule entre ses établissements
/// retrouverait sinon un cache vide à chaque retour. L'index porte l'école de
/// chaque pièce, et toutes ses lectures filtrent dessus. Retirer une école d'un
/// appareil réaffecté reste à spécifier (§10.5).
///
/// ## Ce que l'effacement fait
///
/// [EditiqueDocumentCache.purgeAll] efface les fichiers, **détruit la clé** et
/// vide l'index. La clé détruite est ce qui rend l'effacement démontrable même
/// si une suppression de fichier échoue : ce qui resterait sur le disque ne
/// serait plus déchiffrable par personne, et le prochain démarrage le balaierait
/// en constatant une clé neuve.
///
/// ## Et le curseur, sans quoi l'effacement serait une amputation
///
/// Vider l'index ne suffit pas : le curseur du delta est **monotone**, et il
/// resterait en avance. Le cycle suivant demanderait « ce qui a changé depuis »,
/// le serveur répondrait « rien », et le catalogue resterait vide — non pas le
/// temps d'un cycle, mais **jusqu'à ce que l'établissement scelle une pièce
/// nouvelle**. Une purge rembobine donc les curseurs de TOUTES les écoles —
/// elle a effacé leurs pièces à toutes. Ils vivent avec l'index, dans la base de
/// l'appareil : la purge et le rembobinage ne quittent pas un même fichier.
///
/// Ne lève jamais. Une ouverture de session ne doit pas échouer parce qu'une
/// hygiène de disque a échoué.
class EditiqueCacheSessionGuard {
  final EditiqueDocumentCache _cache;
  final AuthLocalDao _authLocalDao;
  final SyncMetaDao _syncMetaDao;

  const EditiqueCacheSessionGuard({
    required EditiqueDocumentCache cache,
    required AuthLocalDao authLocalDao,
    required SyncMetaDao syncMetaDao,
  }) : _cache = cache,
       _authLocalDao = authLocalDao,
       _syncMetaDao = syncMetaDao;

  /// À appeler à chaque ouverture de session. Rend `true` si le cache a été
  /// effacé — utile aux tests et aux diagnostics, jamais consulté par l'appelant.
  Future<bool> onSessionOpened() async {
    try {
      final user = await _authLocalDao.getSessionUser();
      if (EditiqueCacheEntitlement.isAllowed(user?.role)) return false;
      await _purge();
      return true;
    } catch (_) {
      // Base illisible, cache indisponible : sans conséquence sur la session.
      return false;
    }
  }

  /// Efface le cache **et** rembobine le delta : les deux vont ensemble, ou
  /// l'effacement ampute.
  Future<void> _purge() async {
    await _cache.purgeAll();
    await _syncMetaDao.deleteCursorsOf(kEditiqueDocumentsResource);
  }
}
