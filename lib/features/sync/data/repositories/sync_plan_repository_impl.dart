import 'dart:convert';

import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/owner_scope.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
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
  /// Un verdict serveur (route absente, refus) N'est PAS un échec de relecture :
  /// il a bien été obtenu, et le retenter en boucle ne changerait rien. Il
  /// remonte donc comme un état, et l'appelant cesse de marquer le plan à
  /// relire.
  @override
  Future<SyncPlanState?> refreshFromNetwork() => _fetch();

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
    final parsed = _decode(raw);
    return _stateOf(parsed.plan, rejectedKeys: parsed.rejectedKeys);
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
      // Une route absente ou un refus sont des verdicts : ils ne seront pas
      // démentis par le cache, qui vient du même serveur. Un incident de
      // transport, lui, laisse sa chance au cache.
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

    final state = _stateOf(plan, rejectedKeys: parsed.rejectedKeys);
    // Le plan d'un autre compte n'est pas mis en cache : il n'a rien à faire
    // sur cette tablette sous cette identité, et l'écrire écraserait le nôtre.
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
  SyncPlanState _stateOf(
    SyncPlan? plan, {
    Set<String> rejectedKeys = const <String>{},
  }) {
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
    // Le contrat promet un plan jamais vide — il contient au minimum le socle.
    // Un `streams` vide est donc un serveur qui se contredit ; on le traite en
    // information (rien à tirer, rien à purger) plutôt qu'en panne, mais
    // surtout pas comme « inconnu », qui ferait au contraire tout tirer.
    if (plan.streams.isEmpty) {
      return SyncPlanState.empty(plan, rejectedKeys: rejectedKeys);
    }
    return SyncPlanState.known(plan, rejectedKeys: rejectedKeys);
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
