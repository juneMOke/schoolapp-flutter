import 'dart:convert';

import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/owner_scope.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_repository.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/sync/data/datasources/sync_plan_api.dart';
import 'package:school_app_flutter/features/sync/data/models/sync_plan_parser.dart';

/// Lit le plan : réseau d'abord, cache ensuite, repli « inconnu » toujours.
///
/// **Ne lève jamais.** Chaque échec devient un [SyncPlanUnknownCause] : c'est la
/// forme que prend la trace exigée par le contrat dans un dépôt qui n'a aucun
/// canal de log.
class SyncPlanRepositoryImpl implements SyncPlanRepository {
  final SyncPlanApi _api;
  final SyncMetaDao _syncMetaDao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  /// Clé sentinelle de `sync_meta` — **scopée par compte**.
  ///
  /// Zéro bump de schéma : la table accueille déjà `__global_last_sync__` par le
  /// même détournement, et sa colonne `cursor` est un TEXT libre sans contrainte
  /// de taille.
  ///
  /// ⚠️ Le scope est indispensable, et il ne suffit pas. `sync_meta` n'a que
  /// `resource` pour clé primaire : une clé nue ferait relire au compte B, hors
  /// ligne, le plan du compte A resté sur la tablette — et sous F5, ce plan
  /// **déterminerait** ce que B tire. Mais `scopedResource` rend la clé
  /// inchangée quand l'uid est absent (backend hérité sans revendication
  /// `uid`) : la comparaison de `subject` reste donc le seul filet dans ce
  /// cas-là, et elle est faite à chaque relecture.
  static const String kPlanResource = '__sync_plan__';

  const SyncPlanRepositoryImpl({
    required SyncPlanApi api,
    required SyncMetaDao syncMetaDao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _syncMetaDao = syncMetaDao,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  String get _cacheKey => scopedResource(kPlanResource, _currentUser.uid);

  @override
  Future<SyncPlanState> load() async {
    final fetched = await _fetch();
    if (fetched != null) return fetched;
    // Le réseau n'a rien donné d'exploitable : ce que la tablette a déjà vaut
    // mieux que rien. Un plan en cache reste soumis au même contrôle de
    // `subject` que s'il venait d'arriver.
    return loadCached();
  }

  /// La jambe réseau seule, sans repli sur le cache.
  ///
  /// `_fetch` rend déjà `null` sur un incident de transport — c'est le signal
  /// que `load` interprète comme « laisse sa chance au cache ». Ici on le
  /// remonte tel quel : l'appelant veut savoir si sa relecture a abouti, pas
  /// obtenir un plan à tout prix.
  ///
  /// Une réponse du serveur (route absente, refus, plan d'un autre sujet) N'est
  /// PAS un échec de relecture : elle a bien été obtenue, et le cache — qui
  /// vient du même serveur — ne la démentira pas. Elle remonte donc comme un
  /// état.
  ///
  /// ⚠️ Ce qui ne veut pas dire que l'appelant cesse de relire : c'est
  /// [SyncPlanUnknownCause.isVerdict] qui en décide, et le refus n'en est pas
  /// un. Cette méthode répond « la jambe réseau a-t-elle abouti », pas « faut-il
  /// retenter » — les avoir confondues gelait le repli pour toute la session.
  ///
  /// ⚠️ **Le corps illisible fait exception, et c'est tout l'objet de cette
  /// méthode.** Un 200 qu'on ne sait pas lire, c'est le portail captif — le
  /// dépôt le nomme lui-même comme LE cas de cette cause. Or un portail est
  /// transitoire par construction : une fois franchi, le même GET aboutit.
  /// Le compter comme un verdict éteignait le drapeau « à relire », donc figeait
  /// le plan sur `malformed` pour TOUTE la session — et sous F5 un plan inconnu
  /// rend la main à `requiredPermissions`, c'est-à-dire au comportement d'avant
  /// ce chantier, derrière une pastille verte (`isDegraded` ignore ce cas). Le
  /// mécanisme entier s'annulait sur l'incident le plus banal d'un wifi d'école,
  /// sans autre issue qu'un changement de droits ou une déconnexion.
  ///
  /// On le traite donc comme un échec de relecture : repli sur le cache, drapeau
  /// laissé levé, nouvelle tentative au cycle suivant — exactement un timeout.
  ///
  /// ⚠️ Le plan **dont aucun flux n'est exploitable** ne suit PAS cette
  /// exception, alors qu'il lui ressemble : lui aussi est un corps reçu qu'on ne
  /// sait pas exploiter. Mais la question n'est pas « a-t-on compris », elle est
  /// « une nouvelle tentative donnerait-elle autre chose » — et non : le serveur
  /// rendra le même corps tant que l'APK n'aura pas appris son vocabulaire. Le
  /// retenter, c'est un aller-retour par cycle, indéfiniment, sur tout un parc.
  ///
  /// ⚠️ Ne surtout PAS déplacer cette règle dans `_fetch` : `load()` s'en sert
  /// au premier démarrage, où il n'y a pas de cache, et y perdrait le
  /// diagnostic `malformed` au profit d'`absent`. La distinction entre « le
  /// serveur a répondu n'importe quoi » et « on n'a jamais rien reçu » est la
  /// seule trace dont dispose un dépôt sans logger.
  @override
  Future<SyncPlanState?> refreshFromNetwork() async {
    final fetched = await _fetch();
    if (fetched is SyncPlanUnknown &&
        fetched.cause == SyncPlanUnknownCause.malformed) {
      return null;
    }
    return fetched;
  }

  @override
  Future<SyncPlanState> loadCached() async {
    String? raw;
    try {
      raw = await _syncMetaDao.getCursor(_cacheKey);
    } catch (_) {
      // Base indisponible (tests, plateforme partielle) : pas de plan, jamais
      // d'exception remontée dans le cycle de synchro.
      return const SyncPlanState.unknown(SyncPlanUnknownCause.absent);
    }
    if (raw == null || raw.isEmpty) {
      return const SyncPlanState.unknown(SyncPlanUnknownCause.absent);
    }
    return _stateOf(_decode(raw));
  }

  /// Un cycle réseau. `null` = rien d'exploitable, l'appelant retombe au cache.
  ///
  /// Ne distingue pas les causes de transport entre elles : ce qui compte est
  /// qu'aucune ne doit être confondue avec « le serveur ne connaît pas cette
  /// route ». Un 404 est le **cas nominal du dégradé** — l'APK se met à jour
  /// indépendamment du back — là où un timeout est transitoire.
  Future<SyncPlanState?> _fetch() async {
    final Object? body;
    try {
      final response = await _api.getPlan(_requiredAuth);
      body = response.data;
    } on Object catch (error) {
      final cause = _causeOf(error);
      // Une route absente ou un refus sont des réponses : le cache, qui vient du
      // même serveur, ne les démentira pas. Un incident de transport, lui,
      // laisse sa chance au cache.
      if (cause == SyncPlanUnknownCause.transport) return null;
      return SyncPlanState.unknown(cause);
    }

    final parsed = parseSyncPlan(body);
    final plan = parsed.plan;
    if (plan == null) {
      // Corps illisible : ne RIEN écrire en cache — ni le plan, ni un
      // horodatage de fraîcheur. Un repli ne doit pas se lire comme une
      // synchronisation réussie.
      return const SyncPlanState.unknown(SyncPlanUnknownCause.malformed);
    }

    final state = _stateOf(parsed);
    // **Aucun état inconnu n'est mis en cache**, et la règle vaut pour ses deux
    // familles. Le plan d'un autre compte n'a rien à faire sur cette tablette
    // sous cette identité, et l'écrire écraserait le nôtre. Un plan dont ce
    // client ne comprend aucun flux, lui, est le cas où la mise en cache faisait
    // le plus de dégâts : elle rendait le repli PERMANENT — au redémarrage
    // suivant, la relecture du cache reproduisait le même verdict, et seule une
    // mise à jour d'APK en sortait.
    if (state is! SyncPlanUnknown) await _cache(body);
    return state;
  }

  /// Le contrôle qui décide entre les trois états.
  ///
  /// **`subject` discordant ⇒ inconnu, jamais vide.** Un plan calculé pour A ne
  /// dit rien de ce que B doit tirer ; le lire comme « B n'a rien à tirer »
  /// couperait la synchronisation de B en affirmant une chose fausse.
  ///
  /// **Un uid local absent vaut « inconnu », pas « discordant ».** Le holder
  /// rend `null` sur un backend hérité sans revendication `uid`. Le repli est
  /// alors permanent dans les deux cas — le plan ne peut être attribué à
  /// personne, donc il ne gouvernera jamais — et c'est le verdict correct : ce
  /// qu'on ne peut pas apparier, on ne l'applique pas. Ce que la distinction
  /// change n'est pas le comportement mais le **diagnostic** : `absent` dit
  /// « cette tablette ne sait pas qui elle est », `foreignSubject` dirait « le
  /// serveur a répondu pour quelqu'un d'autre » — et enverrait chercher une
  /// panne de tablette partagée qui n'existe pas.
  SyncPlanState _stateOf(SyncPlanParseResult parsed) {
    final plan = parsed.plan;
    if (plan == null) {
      return const SyncPlanState.unknown(SyncPlanUnknownCause.malformed);
    }
    final uid = _currentUser.uid;
    if (uid == null || uid.isEmpty) {
      return const SyncPlanState.unknown(SyncPlanUnknownCause.absent);
    }
    if (plan.subject != uid) {
      return const SyncPlanState.unknown(SyncPlanUnknownCause.foreignSubject);
    }
    // ⚠️ **« Le client n'a rien compris » n'est pas « il n'y a rien à tirer ».**
    // Le serveur a annoncé des flux et l'analyse les a tous écartés : le plan
    // est vide, mais d'une VIDUITÉ QUI VIENT DE NOUS. Les confondre coûtait le
    // parc entier — l'état vide arrête tout le pull non-socle, le corps partait
    // en cache, et la panne survivait au redémarrage jusqu'à une mise à jour
    // d'APK. Contrôlé APRÈS le `subject` : un plan qu'on ne peut attribuer à
    // personne n'est pas à nous d'interpréter, et `foreignSubject` reste le
    // diagnostic le plus actionnable (tablette partagée).
    if (parsed.allStreamsDropped) {
      return const SyncPlanState.unknown(
        SyncPlanUnknownCause.unsupportedStreams,
      );
    }
    // Le contrat promet un plan jamais vide — il contient au minimum le socle.
    // Un `streams` vide est donc un serveur qui se contredit ; on le traite en
    // information (rien à tirer, rien à purger) plutôt qu'en panne, mais
    // surtout pas comme « inconnu », qui ferait au contraire tout tirer. Ce
    // `streams` vide-là est bien celui du serveur : le cas ci-dessus a déjà
    // retiré celui que l'analyse aurait vidé.
    if (plan.streams.isEmpty) {
      return SyncPlanState.empty(plan);
    }
    return SyncPlanState.known(plan, rejectedKeys: parsed.rejectedKeys);
  }

  /// Le corps **brut** est mis en cache, jamais le plan re-sérialisé : un flux
  /// écarté aujourd'hui faute de `mode` connu doit redevenir exploitable dès que
  /// le client sait le traiter, sans nouvel aller-retour. D'où une relecture qui
  /// ré-analyse, et qui recalcule donc ses propres clés écartées.
  SyncPlanParseResult _decode(String raw) {
    try {
      return parseSyncPlan(jsonDecode(raw));
    } catch (_) {
      // Cache corrompu : indistinguable d'un corps illisible, même verdict.
      return const SyncPlanParseResult.malformed();
    }
  }

  Future<void> _cache(Object? body) async {
    try {
      await _syncMetaDao.setCursor(
        _cacheKey,
        cursor: jsonEncode(body),
        // `setCursor` écrit toujours le couple : l'horodatage vient donc gratuit
        // et date la récupération du plan, pas une synchro de ressource.
        syncedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Persistance best-effort : un cache non écrit coûte un aller-retour au
      // prochain démarrage, il ne casse pas le cycle courant.
    }
  }

  /// Traduit un échec d'appel en cause typée.
  ///
  /// ⚠️ Le mappage du dépôt est **inversé par rapport à l'intuition** : un 401
  /// devient `InvalidCredentialsFailure` et c'est le 403 qui donne
  /// `UnauthorizedFailure`. On lit donc le statut brut plutôt que le type de
  /// `Failure`, qui induirait en erreur ici.
  SyncPlanUnknownCause _causeOf(Object error) {
    final status = _statusOf(error);
    if (status == 404) return SyncPlanUnknownCause.notDeployed;
    // Le contrat promet « jamais 403 » : un refus est une anomalie de
    // déploiement (garde posée par erreur), pas un manque de droit.
    if (status == 401 || status == 403) {
      return SyncPlanUnknownCause.unauthorized;
    }
    return SyncPlanUnknownCause.transport;
  }

  /// Le statut HTTP d'une erreur, sans dépendre du type concret de l'exception.
  ///
  /// Écrit défensivement : ce chemin ne doit jamais lever à son tour, et il est
  /// traversé par tout ce que Dio, Retrofit ou le socle peuvent produire.
  int? _statusOf(Object error) {
    try {
      final dynamic dynamicError = error;
      final status = dynamicError.response?.statusCode;
      return status is int ? status : null;
    } catch (_) {
      return null;
    }
  }
}
