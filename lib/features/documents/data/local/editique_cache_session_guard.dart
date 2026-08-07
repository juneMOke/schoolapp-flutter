import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/data/repositories/offline/editique_document_pull_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';

/// Clé `sync_meta` mémorisant l'école dont les pièces sont sur ce disque.
///
/// Ce n'est pas un curseur, mais c'est bien la table des métadonnées locales, et
/// la colonne accueille une valeur opaque. Sans cette trace, aucun changement
/// d'école ne serait détectable : rien, dans le socle, ne compare l'école
/// entrante à la précédente.
const String kEditiqueCacheSchoolResource = 'editique_cache_school';

/// Ce qu'une ouverture de session décide du cache de pièces scellées
/// (ADR-012 D-7, RG-012-21).
///
/// ## Pourquoi à l'ouverture, et pas à la fermeture
///
/// À la fermeture, le contexte courant est déjà vidé et la seule école
/// connaissable serait la **sortante** : purger « les écoles étrangères »
/// y effacerait exactement l'inverse de ce qu'il faut. Et surtout, effacer à
/// chaque déconnexion viderait le cache tous les soirs sur une tablette
/// partagée — la disponibilité hors ligne, seule raison d'être de ce cache,
/// disparaîtrait avec.
///
/// À l'ouverture, au contraire, tout est connu : le rôle, l'école, et ce que le
/// disque contenait avant. Les octets, eux, sont chiffrés entre-temps.
///
/// ## Ce qui déclenche un effacement
///
/// Deux situations, et deux seulement :
///
///  - **le profil n'a pas droit au cache** (RG-012-4) — un enseignant ouvre une
///    session sur une tablette d'administration, et ce qu'elle contenait ne doit
///    pas rester à sa portée ;
///  - **l'école a changé** (RG-012-21) — la tablette a été réaffectée, et les
///    pièces de l'établissement précédent n'ont plus rien à faire ici.
///
/// Une déconnexion ordinaire suivie d'une reconnexion du même profil dans la
/// même école ne déclenche rien : il n'y a aucune raison de faire retélécharger
/// à un guichet ce qu'il détenait la veille.
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
/// nouvelle**. Une purge doit donc rembobiner le curseur au bootstrap, faute de
/// quoi elle n'efface pas un cache : elle prive la tablette de tout ce que
/// l'école a produit avant.
///
/// Ne lève jamais. Une ouverture de session ne doit pas échouer parce qu'une
/// hygiène de disque a échoué.
class EditiqueCacheSessionGuard {
  final EditiqueDocumentCache _cache;
  final AuthLocalDao _authLocalDao;
  final SyncMetaDao _syncMetaDao;
  final Clock _now;

  const EditiqueCacheSessionGuard({
    required EditiqueDocumentCache cache,
    required AuthLocalDao authLocalDao,
    required SyncMetaDao syncMetaDao,
    Clock now = systemClock,
  }) : _cache = cache,
       _authLocalDao = authLocalDao,
       _syncMetaDao = syncMetaDao,
       _now = now;

  /// À appeler à chaque ouverture de session. Rend `true` si le cache a été
  /// effacé — utile aux tests et aux diagnostics, jamais consulté par l'appelant.
  Future<bool> onSessionOpened() async {
    try {
      final user = await _authLocalDao.getSessionUser();
      final previousSchool = await _syncMetaDao.getCursor(
        kEditiqueCacheSchoolResource,
      );

      if (!EditiqueCacheEntitlement.isAllowed(user?.role)) {
        // Aucune école n'est mémorisée pour un profil sans droit : il ne doit
        // rien laisser derrière lui, pas même la trace de ce qu'il a effacé.
        await _purge();
        await _forgetSchool();
        return true;
      }

      final school = user!.schoolId;
      if (previousSchool != null && previousSchool != school) {
        await _purge();
        await _rememberSchool(school);
        return true;
      }

      await _rememberSchool(school);
      return false;
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

  Future<void> _rememberSchool(String schoolId) => _syncMetaDao.setCursor(
    kEditiqueCacheSchoolResource,
    cursor: schoolId,
    syncedAt: _now(),
  );

  Future<void> _forgetSchool() => _syncMetaDao.setCursor(
    kEditiqueCacheSchoolResource,
    cursor: null,
    syncedAt: _now(),
  );
}
