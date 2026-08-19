import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/revocation_evaluator.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/core/offline/session_reauthenticator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_heartbeat.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';

/// Cubit global d'état de synchronisation : source de vérité de la
/// [SyncIndicator] montée dans la barre supérieure.
///
/// Agrège les signaux du socle offline et les projette sur [SyncStatus] :
///  - hors-ligne ([ConnectivityService]) → [SyncStatus.offline] ;
///  - flush en cours ([SyncEngine.isFlushing]) → [SyncStatus.syncing] ;
///  - au moins une entrée en erreur ([OutboxDao.errorCount]) →
///    [SyncStatus.syncConflict] ;
///  - file d'attente non vide ([OutboxDao.pendingCount]) →
///    [SyncStatus.pendingUpload] ;
///  - sinon → [SyncStatus.synced].
///
/// Sert aussi de colle du « sync loop » : à chaque passage à *online*, **à
/// l'ouverture de session** ([syncOnLogin], ADR-015 F0) **et au retour de
/// l'application au premier plan** ([syncOnResume]), il déclenche un flush
/// opportuniste de l'outbox **puis un pull delta** ([PullCoordinator],
/// optionnel) des ressources de référence — ce sont les trois seuls
/// déclencheurs globaux. Les écrans qui écrivent en local appellent
/// [notifyLocalWrite] après une écriture réussie pour rafraîchir immédiatement
/// la pastille (push seul, **sans** pull).
///
/// **Entièrement défensif** : aucun accès plugin/base ne doit faire remonter une
/// exception dans l'arbre de widgets — les tests ne mockent pas
/// `connectivity_plus`, et la base peut être indisponible. En cas d'échec on
/// conserve le dernier état connu.
class SyncStatusCubit extends Cubit<SyncStatusState> {
  final OutboxDao _outbox;
  final ConnectivityService _connectivity;
  final SyncEngine _syncEngine;
  final PullCoordinator? _pullCoordinator;
  final RevocationEvaluator? _revocationEvaluator;
  final SessionCredentialsProbe? _credentialsProbe;
  final SessionReauthenticator? _reauthenticator;
  final SyncMetaDao _syncMetaDao;

  /// Horloge injectable (epoch ms) — même typedef que le moteur de synchro, pour
  /// que l'anti-rafale de [syncOnResume] soit déterministe en test.
  final Clock _now;

  /// Clé `sync_meta` sentinelle (ne correspond à aucune ressource métier) où
  /// est persistée la date de dernière synchro globale (badge top bar).
  static const String _kGlobalLastSyncResource = '__global_last_sync__';

  /// Epoch ms **heure serveur** de la dernière synchro connue — hydraté au
  /// démarrage depuis `sync_meta`, avancé uniquement par un pull réussi avec
  /// données (jamais régressé par un simple changement de [SyncStatus]).
  int? _lastSyncAtMs;

  /// Dernier relevé de « la file contient des écritures retenues ». Mémorisé
  /// comme [_lastSyncAtMs] : `_safeEmit` est appelé depuis des chemins qui ne
  /// relisent pas la file (offline, syncing), et le drapeau ne doit pas
  /// clignoter à chaque transition d'état.
  bool _hasHeldWork = false;

  /// Dernier cycle de **lecture** connu n'a pas tout ramené (ADR-015 F1).
  ///
  /// Mémorisé comme [_lastSyncAtMs] et [_hasHeldWork], et pour la même raison
  /// en plus forte : [refresh] est appelé depuis neuf chemins qui n'ont fait
  /// AUCUN pull (fin de flush, hydratation, gates, écriture locale, fermeture
  /// de la feuille). Recalculé là, le drapeau s'éteindrait à la première
  /// écriture de l'utilisateur — quelques secondes après s'être allumé.
  ///
  /// N'est écrit que par un cycle qui a réellement observé quelque chose : un
  /// rapport `skipped` (cycle déjà en vol) ou `offline` ne dit rien, et
  /// l'écraser avec « sain » effacerait une dégradation bien réelle.
  bool _pullDegraded = false;

  /// Parmi les causes de [_pullDegraded], au moins une est un **échec de
  /// transport** et non un refus de droits.
  ///
  /// La nuance décide s'il existe un geste à offrir. Un droit manquant est
  /// sauté à chaque cycle : proposer « Réessayer » promettrait de lever une
  /// condition que le geste ne touche pas. Un timeout, lui, se réessaie — et
  /// sans ce bouton personne ne le pourrait au moment où il le décide : le
  /// battement finit par retirer (cf. [kFullCycleMaxAgeMs]), mais un quart
  /// d'heure plus tard, et une tablette en Wi-Fi permanent ne voit toujours
  /// aucun des trois déclencheurs événementiels de la journée. Mémorisé comme
  /// [_pullDegraded], et pour la même raison.
  bool _pullRetriable = false;

  /// Horloge **device** (epoch ms) de la dernière **tentative** de cycle, quel
  /// qu'en soit le déclencheur et quelle qu'en soit l'issue.
  ///
  /// Estampillée avant toute garde, délibérément : un cycle arrêté par un mint
  /// impossible est exactement celui qu'une reprise d'application ne doit pas
  /// relancer en rafale.
  ///
  /// ⚠️ **Ne dit RIEN de la fraîcheur du cache** — c'est [_lastPullAtMs] qui la
  /// porte. Les confondre laissait un cycle qui n'avait rien tiré (portail
  /// captif, jetons refusés) déclarer le cache frais pour un quart d'heure de
  /// plus, ce qui est précisément la panne que le battement de lecture existe à
  /// réparer.
  int? _lastCycleAttemptAtMs;

  /// Horloge **device** (epoch ms) du dernier cycle qui a réellement **tiré**.
  ///
  /// Avancée seulement quand le coordinateur a rendu un rapport exploitable —
  /// ni `skipped` (cycle déjà en vol) ni `offline`. C'est la mesure d'âge du
  /// cache, et donc la seule que consulte [_isFullCycleDue].
  ///
  /// Distincte de [_lastSyncAtMs], qui porte l'heure **serveur** du dernier
  /// pull *fructueux* : celle-là s'affiche, celle-ci décide.
  int? _lastPullAtMs;

  StreamSubscription<bool>? _connectivitySub;

  /// Cadence du battement — le timer et ses conditions d'armement vivent là
  /// (cf. [SyncHeartbeat]). Ce cubit ne garde que la **politique** du tic.
  late final SyncHeartbeat _heartbeat;

  static const Duration kDefaultHeartbeatInterval = Duration(seconds: 45);

  /// Âge au-delà duquel le battement ne se contente plus de pousser : il tire.
  ///
  /// C'est le pendant *lecture* du battement (lot 3), et il répond à une panne
  /// distincte de celle du push. Une tablette allumée le matin dans une école
  /// déjà couverte en Wi-Fi ouvre sa session, exécute son cycle, et n'en voit
  /// plus jamais : ni transition réseau, ni reprise d'application si elle reste
  /// posée sur le même écran. Elle travaillait donc la journée entière sur le
  /// cache du matin — un tarif changé à 9 h, une classe recomposée à 11 h,
  /// invisibles jusqu'au lendemain.
  ///
  /// Un quart d'heure : assez espacé pour que la pagination de dix-neuf
  /// ressources reste marginale sur la connexion d'une école (et la plupart
  /// répondent 304), assez serré pour qu'une correction de référentiel arrive
  /// dans la demi-heure.
  static const int kFullCycleMaxAgeMs = 900000;

  /// Plancher entre deux cycles quand ils échouent — un portail captif laisse
  /// le cache éternellement périmé, donc [kFullCycleMaxAgeMs] serait franchi à
  /// chaque tic. Cinq minutes : la reprise reste bien plus rapide que l'âge
  /// maximum, sans qu'un réseau qui ment coûte un cycle complet par tic.
  static const int kFailedCycleRetryMs = 300000;

  /// Fenêtre en-deçà de laquelle une reprise d'application ne relance PAS le
  /// cycle complet (cf. [syncOnResume]). Cinq minutes : au-delà, l'utilisateur
  /// est resté assez longtemps ailleurs pour qu'un référentiel ait bougé ;
  /// en-deçà, son cache est frais et seule sa file d'écritures mérite un geste.
  static const int kResumeFullCycleMinIntervalMs = 300000;

  SyncStatusCubit({
    required OutboxDao outbox,
    required ConnectivityService connectivity,
    required SyncEngine syncEngine,
    required SyncMetaDao syncMetaDao,
    PullCoordinator? pullCoordinator,
    RevocationEvaluator? revocationEvaluator,
    SessionCredentialsProbe? credentialsProbe,
    SessionReauthenticator? reauthenticator,
    Clock now = systemClock,
    Duration heartbeatInterval = kDefaultHeartbeatInterval,
  }) : _outbox = outbox,
       _connectivity = connectivity,
       _syncEngine = syncEngine,
       _syncMetaDao = syncMetaDao,
       _pullCoordinator = pullCoordinator,
       _revocationEvaluator = revocationEvaluator,
       _credentialsProbe = credentialsProbe,
       _reauthenticator = reauthenticator,
       _now = now,
       super(const SyncStatusState(status: SyncStatus.synced)) {
    _heartbeat = SyncHeartbeat(
      interval: heartbeatInterval,
      onTick: _onHeartbeat,
    );
    _listenConnectivity();
    // Un flush peut être déclenché AILLEURS qu'ici : les repositories offline
    // flushent en direct après chaque écriture locale. Sans cet abonnement,
    // l'état reste bloqué sur `syncing` jusqu'à un prochain événement réseau —
    // et un conflit apparu pendant ce flush n'est jamais affiché.
    _unsubscribeFlush = _syncEngine.addFlushCompleteListener(
      () => unawaited(refresh()),
    );
    unawaited(_hydrateThenRefresh());
  }

  void Function()? _unsubscribeFlush;

  /// Restaure la date de dernière synchro persistée (survit au redémarrage)
  /// avant le premier calcul de statut — défensif : une base indisponible
  /// (tests, plateforme partielle) laisse simplement `_lastSyncAtMs` à `null`.
  ///
  /// Passe par [_advanceLastSync] (pas une affectation directe) : si un cycle
  /// de reconnexion réel a déjà avancé `_lastSyncAtMs` pendant que cette
  /// lecture était en vol, la valeur hydratée (plus ancienne) ne doit pas
  /// écraser la plus récente déjà connue.
  Future<void> _hydrateThenRefresh() async {
    try {
      final hydrated = await _syncMetaDao.getSyncedAt(_kGlobalLastSyncResource);
      if (hydrated != null) await _advanceLastSync(hydrated);
    } catch (_) {
      // Base indisponible : pas de date affichée plutôt qu'une exception.
    }
    await refresh();
  }

  void _listenConnectivity() {
    try {
      _connectivitySub = _connectivity.onStatusChange.listen(
        _onConnectivityChanged,
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // Plateforme sans connectivity_plus (tests) : abonnement ignoré.
    }
  }

  Future<void> _onConnectivityChanged(bool online) async {
    if (!online) {
      _safeEmit(SyncStatus.offline);
      return;
    }
    await _syncOnReconnect();
  }

  /// Au retour *online* : ordre **`flush → evaluate → pull`** (ADR-010 D-11).
  ///
  /// 1. **POUSSE** l'outbox (le travail légitime saisi offline est drainé
  ///    d'abord — un `userVersion++` ne détruit jamais un paiement en file) ;
  /// 2. **ÉVALUE** la révocation (`userVersion` observé vs local) : en cas de
  ///    divergence, la session est wipée (jamais l'outbox) et on **saute le
  ///    pull** (on repasse `unauthenticated`) ;
  /// 3. sinon **TIRE** (pull delta) pour rafraîchir le cache local.
  ///
  /// Le pull est silencieux (304 fréquent) et **n'altère pas** l'état de synchro,
  /// qui ne reflète que la file de push.
  Future<void> _syncOnReconnect({bool evaluateRevocation = true}) async {
    // Estampillé AVANT les gardes, et non après un cycle réussi : un cycle
    // arrêté faute de jetons ou de mint est exactement celui qu'une reprise
    // d'application ne doit pas relancer en rafale (cf. [syncOnResume]).
    // ⚠️ Ceci N'EST PAS une mesure de fraîcheur du cache : voir [_lastPullAtMs].
    _lastCycleAttemptAtMs = _now();
    // Gate crédentiels (V1.1) : une session ouverte OFFLINE peut être sans
    // jetons (logout sans consigne, purge d'identité croisée, consigne brûlée).
    // Flusher quand même = 401 systématique sur CHAQUE entrée → `attempts++`
    // jusqu'au poison SYNC_ERROR, sans qu'aucune écriture n'ait pu partir.
    // On ne tente donc RIEN (ni flush, ni pull — tous deux authentifiés) et
    // `refresh()` surfacera « Reconnexion requise » à la place.
    if (!await _canAuthenticate()) {
      await refresh();
      return;
    }
    // Ré-authentification silencieuse AVANT tout appel authentifié (ADR-010) :
    // une session ouverte offline revient avec un access vide (déconsignation)
    // ou périmé (TTL en heures, coupure en jours). Laisser la première requête
    // métier porter le renouvellement, c'est consommer une tentative d'outbox
    // par entrée pour un jeton mort — et dépendre d'un 401 propre du serveur.
    // Mint impossible (infra, proxy, portail) → on ne tente RIEN : la session
    // reste ouverte, l'utilisateur reste sur son écran, la file reste intacte,
    // le prochain cycle retentera.
    if (!await _ensureFreshAccess()) {
      await refresh();
      return;
    }
    _safeEmit(SyncStatus.syncing);
    try {
      await _syncEngine.flush();
    } catch (_) {
      // flush() encapsule déjà ses erreurs ; garde-fou par prudence.
    }
    bool revoked = false;
    if (evaluateRevocation) {
      try {
        revoked = await _revocationEvaluator?.evaluateRevocation() ?? false;
      } catch (_) {
        // evaluateRevocation ne lève pas (contrat) ; garde-fou par prudence.
      }
    }
    if (!revoked) {
      try {
        final report = await _pullCoordinator?.pullAll();
        // L'âge du cache n'avance QUE sur un cycle qui a réellement observé
        // quelque chose. Un rapport `skipped` (cycle déjà en vol) ou `offline`
        // ne dit rien, et le compter pour frais figerait le référentiel pour un
        // quart d'heure de plus. Aucun coordinateur branché : il n'y a rien à
        // tirer, donc rien qui puisse vieillir.
        if (report == null) {
          _lastPullAtMs = _now();
        } else if (!report.skipped && !report.offline) {
          _pullDegraded = report.isDegraded;
          _pullRetriable = report.failed > 0;
          _lastPullAtMs = _now();
        }
        final observed = report?.latestServerTimeMs;
        if (observed != null) await _advanceLastSync(observed);
      } catch (_) {
        // pullAll() encapsule déjà ses erreurs ; garde-fou par prudence.
      }
    }
    await refresh();
  }

  /// Cycle complet à l'ouverture de session (ADR-015 F0).
  ///
  /// Jusqu'ici [_syncOnReconnect] n'avait qu'un déclencheur — la transition
  /// hors-ligne → en ligne. Une tablette allumée le matin dans une école déjà
  /// couverte en Wi-Fi n'exécutait donc **aucun** cycle de coordinateur de la
  /// journée : le cache n'était hydraté que par les pulls lancés directement
  /// par les écrans, chacun aveugle à l'ordre, aux droits et aux curseurs des
  /// autres.
  ///
  /// Emprunte la **même** séquence que le retour réseau (`flush → evaluate →
  /// pull`, ADR-010 D-11) au lieu d'appeler `pullAll()` en direct : le
  /// coordinateur ne connaît ni la sonde de crédentiels ni la
  /// ré-authentification, et un login offline laisse un access vide — chaque
  /// ressource partirait alors en 401, une tentative consommée par entrée.
  Future<void> syncOnLogin() {
    // Arme aussi la cadence, plutôt que de laisser la racine s'en souvenir : un
    // battement qui n'est jamais armé ne se voit sur aucun écran et ne fait
    // échouer aucun test. Un seul fil de session à ne pas oublier vaut mieux
    // que deux — et celui-ci était déjà branché.
    onSessionOpened();
    return syncNow();
  }

  /// Un cycle complet à la demande — l'ouverture de session ([syncOnLogin]) et
  /// la reprise après un échec de transport (bandeau de la feuille de synchro).
  ///
  /// Sans ce point d'entrée public, un cycle qui échoue sur une ressource
  /// laisserait la pastille en « Partiellement à jour » jusqu'au redémarrage de
  /// l'application : les deux autres déclencheurs sont l'ouverture de session,
  /// qui n'arrive qu'une fois, et le retour de la radio, qu'une tablette posée
  /// sur le Wi-Fi de l'école ne verra jamais.
  Future<void> syncNow({bool evaluateRevocation = true}) async {
    // La pastille reflète la file AVANT le premier appel réseau : la suite du
    // cycle peut durer, l'utilisateur n'a pas à l'attendre pour voir qu'il a
    // des écritures en attente.
    await refresh();
    // Session **rouverte** hors connexion : ne rien tenter. Cette pré-garde ne
    // lit que la radio et ne suffit donc pas à elle seule — un login offline
    // survient typiquement radio allumée, serveur injoignable. C'est
    // `_ensureFreshAccess`, un cran plus bas, qui arrête ce cas-là.
    if (!await _isOnline()) return;
    await _syncOnReconnect(evaluateRevocation: evaluateRevocation);
  }

  /// Retour de l'application au premier plan.
  ///
  /// Troisième déclencheur global, et celui qui manquait le plus : les deux
  /// autres n'arrivent qu'une fois (l'ouverture de session) ou jamais (le
  /// retour réseau, qu'une tablette posée sur le Wi-Fi de l'école ne voit pas
  /// de la journée). Or aucun des délais du moteur ne relance quoi que ce soit
  /// : un backoff qui repousse une entrée à +2 s, ou une entrée `blocked`
  /// repoussée à +5 s, ne fixe que le moment où elle redevient *éligible* — pas
  /// celui où quelqu'un la reprend. Le battement couvre depuis le cas de
  /// l'application restée ouverte ; celui-ci couvre celui de l'application
  /// qu'on rouvre, et il agit tout de suite plutôt qu'au prochain tic.
  ///
  /// **Deux régimes, parce qu'une reprise n'est pas un événement rare.**
  /// L'utilisateur qui bascule vers sa calculatrice et revient déclenche ceci
  /// autant de fois qu'il le fait ; un cycle complet à chaque fois relancerait
  /// la pagination de dix-neuf ressources sur la connexion d'une école.
  ///  - reprise **espacée** (≥ [kResumeFullCycleMinIntervalMs] depuis le
  ///    dernier cycle) → cycle complet, pull compris ;
  ///  - reprise **rapprochée** → push seul (même chemin que [notifyLocalWrite]).
  ///    Le cache est frais de toute façon ; ce qui ne l'est pas, c'est la file.
  ///
  /// Comme les autres points d'entrée, entièrement gardé plus bas : hors ligne,
  /// sans jetons ou sans mint possible, il ne tente rien.
  Future<void> syncOnResume() async {
    final since = _elapsedSince(_lastCycleAttemptAtMs);
    if (since == null || since >= kResumeFullCycleMinIntervalMs) {
      await syncNow();
      return;
    }
    await _flushAndRefresh();
  }

  /// Temps écoulé depuis [stampMs], ou `null` s'il est absent — **ou si
  /// l'horloge a reculé**.
  ///
  /// Les trois appelants portent des seuils différents et parfois opposés (un
  /// minimum entre deux cycles, un âge maximum de cache, un plancher de
  /// reprise) mais partagent ce piège-ci, d'où le passage par un seul endroit.
  ///
  /// L'horloge est celle du device (`DateTime.now()`), donc reculable : un NTP
  /// qui corrige une dérive de RTC, ou une date changée à la main, laisse
  /// l'estampille dans le futur. Comparé naïvement, l'écart resterait sous
  /// n'importe quel seuil À JAMAIS : la reprise ne referait plus jamais de
  /// cycle complet, et le battement n'en déclencherait jamais un. Deux
  /// déclencheurs morts en silence pour toute la vie du processus. Rendre
  /// `null` — « on ne sait pas » — les fait tous retomber du côté sûr, celui
  /// qui tire.
  int? _elapsedSince(int? stampMs) {
    if (stampMs == null) return null;
    final elapsed = _now() - stampMs;
    return elapsed < 0 ? null : elapsed;
  }

  // ─── Battement de la file (lots 2 & 3) ───────────────────────────────────
  //
  // Le quatrième déclencheur, et le premier qui ne dépende d'AUCUN geste.
  // Les trois autres sont des événements : on écrit, le réseau revient, on
  // rouvre l'application. Aucun ne survient pendant qu'une entrée attend la fin
  // de son backoff ou la levée de sa dépendance — c'est précisément là que la
  // file dormait.

  /// La session vient de s'ouvrir : le battement peut tourner.
  void onSessionOpened() => _heartbeat.sessionOpened();

  /// La session se ferme : le battement s'arrête. Sans cela, chaque tic
  /// interrogerait la sonde de crédentiels d'une session qui n'en a plus.
  void onSessionClosed() => _heartbeat.sessionClosed();

  /// L'application est au premier plan.
  void onForeground() => _heartbeat.enterForeground();

  /// L'application passe en arrière-plan. Un `Timer` Dart n'y est pas suspendu
  /// tant que l'OS n'a pas gelé le processus : sans cet arrêt, le battement
  /// continuerait de consommer réseau et batterie hors de tout usage — et de
  /// brûler des tentatives d'outbox que personne ne regarde.
  void onBackground() => _heartbeat.leaveForeground();

  /// Vrai si le battement est armé — exposé pour que le câblage se vérifie.
  bool get isHeartbeatActive => _heartbeat.isActive;

  /// Un tic, verrou de réentrance compris.
  @visibleForTesting
  Future<void> heartbeatTick() => _heartbeat.tick();

  /// Ce qu'un tic décide.
  ///
  /// Trois issues, de la moins chère à la plus chère, et l'ordre des gardes est
  /// porteur :
  ///
  ///  1. **hors ligne → rien.** Ni push ni pull n'ont de sens, et sans cette
  ///     garde en TÊTE le cache est toujours réputé périmé (aucun cycle ne peut
  ///     l'avoir rafraîchi), donc chaque tic partait sur la branche chère pour
  ///     redécouvrir l'absence de réseau — deux appels de plateforme et trois
  ///     `COUNT` toutes les 45 s, une journée durant, sans rien produire ;
  ///  2. **un flush est déjà en vol → rien.** Un tic n'a rien à y ajouter. Et
  ///     surtout, la branche du cycle complet ne doit PAS l'ignorer : `flush()`
  ///     rend `skipped` *immédiatement* quand le moteur travaille, il ne se
  ///     sérialise donc pas — la révocation et le pull partiraient par-dessus
  ///     un push en cours, et une session wipée au milieu d'un lot enverrait
  ///     les entrées restantes sans `Authorization`, c'est-à-dire un paiement
  ///     en `SYNC_ERROR` terminal ;
  ///  3. **cache vieilli → cycle complet**, file vide ou non ;
  ///  4. sinon **ce qui est prêt à partir → push seul**, et rien du tout s'il
  ///     n'y a rien de prêt.
  ///
  /// Défensif comme le reste du cubit : le verrou et le filet à exceptions sont
  /// dans [SyncHeartbeat], qui appelle ceci.
  Future<void> _onHeartbeat() async {
    if (_stopBeating) return;
    if (!await _isOnline()) return;
    // Relu après chaque attente : `dispose()` et `sessionClosed()` coupent le
    // timer, mais rien n'interrompt un tic déjà parti. Sans ces reprises, un
    // cycle lancé deux secondes avant un logout continuerait d'écrire
    // référentiel et curseurs pour une session que la racine a déclarée close.
    if (_stopBeating || _syncEngine.isFlushing) return;
    if (_isFullCycleDue()) {
      // Sans évaluation de révocation : celle-ci peut wiper la session et
      // renvoyer l'utilisateur à l'écran de connexion. Les trois autres
      // déclencheurs surviennent quand il ne saisit rien (il se connecte, il
      // revient dans l'application, le réseau rentre) ; un timer, lui, tombe au
      // milieu d'un formulaire. Le verdict n'est pas perdu, il est rendu au
      // prochain de ces trois moments — soit exactement la cadence d'avant.
      await syncNow(evaluateRevocation: false);
      return;
    }
    final ready = await _outbox.pendingReady(_now(), limit: 1);
    if (ready.isEmpty || _stopBeating) return;
    // `announce: false` : ce push n'a été demandé par personne. L'annoncer
    // ferait clignoter la pastille `syncing` → `pendingUpload` toutes les
    // 45 s dès qu'une seule entrée est retenue par le moteur (écriture d'un
    // autre compte, dépendance non satisfaite) — celui-ci la repousse de 5 s,
    // donc elle est de nouveau « prête » à chaque tic, indéfiniment.
    await _flushAndRefresh(announce: false);
  }

  /// Le tic doit-il renoncer ? Relu entre deux étapes (cf. [_onHeartbeat]).
  bool get _stopBeating => isClosed || !_heartbeat.isActive;

  /// Le cache a-t-il assez vieilli pour mériter un cycle complet ?
  ///
  /// Deux questions, pas une. La première porte sur l'âge du **cache**
  /// ([_lastPullAtMs]) : c'est elle qui décide qu'un cycle est dû. La seconde
  /// porte sur la dernière **tentative** ([_lastCycleAttemptAtMs]) et ne sert
  /// qu'à espacer les reprises quand les cycles échouent — un portail captif
  /// laisse le cache éternellement périmé, et sans ce plancher le tic
  /// relancerait un cycle complet toutes les 45 s pour rien.
  bool _isFullCycleDue() {
    final sincePull = _elapsedSince(_lastPullAtMs);
    if (sincePull != null && sincePull < kFullCycleMaxAgeMs) return false;
    final sinceAttempt = _elapsedSince(_lastCycleAttemptAtMs);
    return sinceAttempt == null || sinceAttempt >= kFailedCycleRetryMs;
  }

  /// Avance la date de dernière synchro (heure **serveur**) si [serverTimeMs]
  /// est plus récent que celle connue, et la persiste — `sync_meta` réutilisé
  /// via sa clé sentinelle, aucune migration de schéma. Best-effort : un échec
  /// d'écriture n'empêche pas la valeur en mémoire de refléter ce cycle.
  Future<void> _advanceLastSync(int serverTimeMs) async {
    if (_lastSyncAtMs != null && serverTimeMs <= _lastSyncAtMs!) return;
    _lastSyncAtMs = serverTimeMs;
    try {
      await _syncMetaDao.setCursor(
        _kGlobalLastSyncResource,
        cursor: null,
        syncedAt: serverTimeMs,
      );
    } catch (_) {
      // Persistance best-effort (cf. docstring).
    }
  }

  /// Recalcule le statut depuis l'état courant du réseau et de l'outbox.
  Future<void> refresh() async {
    try {
      if (!await _connectivity.isOnline()) {
        _safeEmit(SyncStatus.offline);
        return;
      }
      if (_syncEngine.isFlushing) {
        _safeEmit(SyncStatus.syncing);
        return;
      }
      final pending = await _outbox.pendingCount();
      // Des écritures attendent mais la session ne peut pas s'authentifier :
      // ni « À envoyer » ni « Conflit » ne diraient la vraie condition de
      // déblocage (un login online) — l'auth est la cause racine qui gèle
      // TOUT le reste, elle prime donc sur le conflit (revue adversariale).
      if (pending > 0 && !await _canAuthenticate()) {
        _safeEmit(SyncStatus.authRequired);
        return;
      }
      // Écritures retenues par le moteur (dépendance non satisfaite, ou
      // écriture d'un autre compte) : ne change AUCUN statut — c'est une
      // attente, pas une erreur — mais rend la feuille atteignable, seul
      // endroit qui explique pourquoi la file ne se vide pas.
      //
      // Isolé dans son propre `try` : c'est un confort d'accessibilité, il ne
      // doit pas pouvoir empêcher le CALCUL DU STATUT. Sans cette isolation,
      // son échec tomberait dans le `catch` global ci-dessous, qui conserve le
      // dernier état connu — la pastille se figerait sur une valeur périmée
      // pour une raison sans rapport avec la synchro.
      try {
        _hasHeldWork = await _outbox.heldCount() > 0;
      } catch (_) {
        _hasHeldWork = false;
      }

      if (await _outbox.errorCount() > 0) {
        _safeEmit(SyncStatus.syncConflict);
        return;
      }
      // « À envoyer » prime sur « partiellement à jour » : le travail de
      // l'utilisateur qui attend est actionnable, une lecture incomplète ne
      // l'est pas. Même raison que les quatre sorties anticipées ci-dessus —
      // hors-ligne, flush, reconnexion et conflit masquent également la
      // dégradation de lecture, et c'est voulu : chacun est une condition plus
      // urgente, et chacun se lève avant qu'elle ne redevienne visible.
      if (pending > 0) {
        _safeEmit(SyncStatus.pendingUpload);
        return;
      }
      _safeEmit(_pullDegraded ? SyncStatus.partiallySynced : SyncStatus.synced);
    } catch (_) {
      // Base/plugin indisponible : on n'écrase pas le dernier état connu.
    }
  }

  /// Sans sonde branchée (tests, plateformes partielles) : pas de gate.
  Future<bool> _canAuthenticate() async {
    final probe = _credentialsProbe;
    if (probe == null) return true;
    try {
      return await probe.canAuthenticate();
    } catch (_) {
      return true; // sonde défaillante : ne pas bloquer la synchro
    }
  }

  /// Sans ré-authentificateur branché (tests, plateformes partielles) : on
  /// laisse passer — l'intercepteur de refresh reste le filet de rattrapage.
  Future<bool> _ensureFreshAccess() async {
    final reauth = _reauthenticator;
    if (reauth == null) return true;
    try {
      return await reauth.ensureFreshAccess();
    } catch (_) {
      return true; // ne pas geler la synchro sur une défaillance de la sonde
    }
  }

  /// À appeler après une écriture locale (write-path) réussie : reflète
  /// immédiatement la file d'attente, puis tente un push opportuniste en fond.
  Future<void> notifyLocalWrite() async {
    await refresh();
    unawaited(_flushAndRefresh());
  }

  Future<void> _flushAndRefresh({bool announce = true}) async {
    // Même gate que le reconnect : sans crédentiels, le push opportuniste
    // post-écriture ne ferait que consommer des tentatives en 401. Et même
    // ré-authentification préalable : ce chemin est celui du login offline
    // (main.dart appelle `notifyLocalWrite` à la transition `authenticated`),
    // donc typiquement celui d'un access vide à renouveler.
    // Hors ligne, ni le mint ni le flush n'ont de sens (le moteur no-ope de
    // toute façon) — et tenter le mint imposerait un timeout réseau à CHAQUE
    // écriture locale, soit exactement le régime de travail hors connexion.
    if (!await _isOnline()) {
      await refresh();
      return;
    }
    if (!await _canAuthenticate()) {
      await refresh();
      return;
    }
    if (!await _ensureFreshAccess()) {
      await refresh();
      return;
    }
    if (announce) _safeEmit(SyncStatus.syncing);
    try {
      await _syncEngine.flush();
    } catch (_) {
      // flush() encapsule déjà ses erreurs ; garde-fou par prudence.
    }
    await refresh();
  }

  /// Défensif comme le reste du cubit : une plateforme sans `connectivity_plus`
  /// (tests) ne doit pas geler la synchro — on suppose alors « en ligne ».
  Future<bool> _isOnline() async {
    try {
      return await _connectivity.isOnline();
    } catch (_) {
      return true;
    }
  }

  void _safeEmit(SyncStatus status) {
    if (isClosed) return;
    final next = SyncStatusState(
      status: status,
      lastSyncAtMs: _lastSyncAtMs,
      hasHeldWork: _hasHeldWork,
      hasIncompleteRead: _pullDegraded,
      hasRetriableRead: _pullDegraded && _pullRetriable,
    );
    if (state != next) emit(next);
  }

  @override
  Future<void> close() {
    _heartbeat.dispose();
    _connectivitySub?.cancel();
    _unsubscribeFlush?.call();
    return super.close();
  }
}
