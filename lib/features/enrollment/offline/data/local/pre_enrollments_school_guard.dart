import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';

/// Clé `sync_meta` mémorisant l'école dont le vivier de préinscriptions est sur
/// ce disque.
///
/// Ce n'est pas un curseur, mais c'est bien la table des métadonnées locales, et
/// la colonne accueille une valeur opaque. Sans cette trace, aucun changement
/// d'école ne serait détectable : rien, dans le socle, ne compare l'école
/// entrante à la précédente.
///
/// ⚠️ Le nom est délibérément **hors du préfixe** du flux : le prédicat de
/// `SyncMetaDao.deleteCursorsOf('enrollment_pre_enrollments')` couvre la clé
/// nue et ses variantes `@…`/`:…`, jamais un suffixe `_school`. Ce marqueur
/// survit donc au rembobinage qu'il déclenche — sans quoi la garde oublierait,
/// à chaque purge, l'école qu'elle vient d'installer, et re-purgerait à la
/// session suivante.
const String kPreEnrollmentsSchoolResource =
    'enrollment_pre_enrollments_school';

/// Ce qu'une ouverture de session décide du vivier `ref_pre_enrollments`.
///
/// ## Le défaut fermé
///
/// Le vivier des préinscriptions descend par un pull keyset, et sa table ne
/// porte **aucune colonne `school_id`**. Sur une tablette réaffectée, les
/// candidats de l'établissement précédent restaient donc lisibles — la
/// recherche PRE les proposait au nouveau guichet, sans rien qui permette de les
/// distinguer des siens. Scoper le curseur par école (voir
/// [preEnrollmentsCursorKey]) fait bien descendre les préinscriptions de la
/// nouvelle école, mais n'efface pas celles de l'ancienne : il faut les deux.
///
/// ## Trois états, et l'absence n'est pas la continuité
///
/// Le marqueur d'école répond à trois choses, pas à deux : « c'est la même
/// école » (on garde), « c'en est une autre » (on purge), et « on ne sait pas »
/// — marqueur jamais posé. Ce troisième cas se lisait comme le premier, et
/// c'était l'erreur : la garde adoptait le disque à la première session, donc
/// précisément sur la tablette déjà réaffectée avant l'installation de ce lot.
/// Il se lit désormais comme le second. Même patron que le tri-état des
/// permissions et que celui du plan de synchro — l'absence d'information n'est
/// jamais une information rassurante.
///
/// ## Pourquoi à l'ouverture, et pas à la fermeture
///
/// À la fermeture, le contexte courant est déjà vidé et la seule école
/// connaissable serait la **sortante**. À l'ouverture, tout est connu : l'école
/// entrante, et ce que le disque portait avant. Une déconnexion ordinaire suivie
/// d'une reconnexion dans la même école ne déclenche rien — il n'y a aucune
/// raison de faire retélécharger à un guichet le vivier qu'il détenait la
/// veille.
///
/// ## Et le curseur, sans quoi la purge serait une amputation
///
/// ⚠️ Depuis la bascule dure du seed vers le local, `ref_pre_enrollments` est la
/// **seule** source d'amorçage d'un brouillon de préinscription : plus aucun
/// repli GET serveur. Vider la table sans rembobiner laisserait le curseur
/// keyset en avance sur des lignes qui n'existent plus ; le serveur répondrait
/// « rien de neuf », et ces préinscriptions seraient définitivement
/// inatteignables — pas le temps d'un cycle, mais jusqu'à ce que le portail
/// parent en produise de nouvelles. La purge rembobine donc **toutes** les
/// variantes scopées du flux, pas seulement celle de l'école sortante : une
/// tablette qui revient à son école d'origine doit rebootstraper elle aussi, son
/// vivier ayant été effacé entre-temps.
///
/// L'ordre — purger, **puis** rembobiner — est celui de l'éditique : un
/// rembobinage qui précéderait la purge laisserait, si le processus meurt entre
/// les deux, une base pleine de lignes étrangères que plus rien ne signale.
/// Dans l'ordre retenu, la même mort laisse une base vide et un curseur en
/// avance : la session suivante re-détecte le changement d'école (le marqueur
/// n'a pas encore bougé) et rejoue le geste entier.
///
/// Ne lève jamais. Une ouverture de session ne doit pas échouer parce qu'une
/// hygiène de disque a échoué.
class PreEnrollmentsSchoolGuard {
  final EnrollmentSeedDao _seedDao;
  final SyncMetaDao _syncMetaDao;
  final CurrentUserContext _currentUser;
  final Clock _now;

  const PreEnrollmentsSchoolGuard({
    required EnrollmentSeedDao seedDao,
    required SyncMetaDao syncMetaDao,
    required CurrentUserContext currentUser,
    Clock now = systemClock,
  }) : _seedDao = seedDao,
       _syncMetaDao = syncMetaDao,
       _currentUser = currentUser,
       _now = now;

  /// À appeler à chaque ouverture de session. Rend `true` si le vivier a été
  /// purgé — utile aux tests et aux diagnostics, jamais consulté par l'appelant.
  Future<bool> onSessionOpened() async {
    try {
      // Même source que la clé du curseur : la garde et le pull doivent
      // s'accorder sur « l'école courante », sinon la garde purgerait au nom
      // d'une école dans laquelle le pull n'écrit pas.
      final school = _currentUser.schoolId;
      // École inconnue : on ne purge rien et on n'oublie rien. Effacer sur une
      // identité absente viderait le vivier d'un guichet qui n'a rien fait de
      // mal ; réécrire le marqueur ferait passer le prochain changement d'école
      // pour une continuité.
      if (school == null || school.isEmpty) return false;

      final previousSchool = await _syncMetaDao.getCursor(
        kPreEnrollmentsSchoolResource,
      );
      // ⚠️ **Un marqueur absent vaut « école inconnue », pas « rien à
      // purger ».** C'est la seule lecture compatible avec le défaut fermé que
      // cette classe défend : un vivier qu'on ne sait attribuer à personne est
      // exactement ce qu'il ne faut pas servir au guichet suivant. Adopter le
      // disque sur cette base rendait la garde inopérante là où elle comptait
      // le plus — à la PREMIÈRE session, celle qui suit la mise à jour, la
      // seule que voit une tablette déjà réaffectée. Les candidats de l'école A
      // restaient alors lisibles par B pour toujours : ni
      // `searchPreEnrollmentCandidates` ni `findPreEnrollmentById` n'ont de
      // prédicat `school_id`, faute de colonne.
      //
      // Le prix est un rebootstrap unique par tablette au premier démarrage
      // après ce lot — table vidée, flux rembobiné, vivier redescendu au cycle
      // suivant. Sur une installation neuve il ne coûte rien : la table est
      // déjà vide et aucun curseur n'existe.
      final sameSchool =
          previousSchool != null &&
          previousSchool.isNotEmpty &&
          previousSchool == school;
      if (!sameSchool) {
        await _purge();
        await _rememberSchool(school);
        return true;
      }

      await _rememberSchool(school);
      return false;
    } catch (_) {
      // Base illisible : sans conséquence sur la session.
      return false;
    }
  }

  /// Vide le vivier **et** rembobine le flux : les deux vont ensemble, ou la
  /// purge ampute (cf. docstring de la classe).
  Future<void> _purge() async {
    await _seedDao.deleteAllPreEnrollments();
    await _syncMetaDao.deleteCursorsOf(kEnrollmentPreEnrollmentsResource);
  }

  Future<void> _rememberSchool(String schoolId) => _syncMetaDao.setCursor(
    kPreEnrollmentsSchoolResource,
    cursor: schoolId,
    syncedAt: _now(),
  );
}
