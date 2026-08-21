import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/revocation_evaluator.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/core/offline/session_reauthenticator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

/// Ce qu'un cycle a observé — de quoi mettre à jour une projection d'état.
///
/// Les champs sont **nullables au sens de « rien à dire »**, jamais « faux » :
/// un cycle arrêté sur une garde, un rapport `skipped` (cycle déjà en vol) ou
/// `offline` n'ont rien observé, et écraser une dégradation bien réelle par
/// « sain » est exactement la panne que ces drapeaux existent à signaler.
class SyncCycleOutcome {
  /// Le dernier cycle de lecture n'a pas tout ramené (ADR-015 F1).
  final bool? pullDegraded;

  /// Parmi les causes, au moins un échec de transport — donc un geste à offrir.
  final bool? pullRetriable;

  /// Horloge **serveur** la plus récente observée, pour le badge de fraîcheur.
  final int? latestServerTimeMs;

  const SyncCycleOutcome({
    this.pullDegraded,
    this.pullRetriable,
    this.latestServerTimeMs,
  });

  /// Rien n'a été observé : garde fermée, ou cycle sans rapport exploitable.
  static const SyncCycleOutcome nothingObserved = SyncCycleOutcome();
}

/// Le **corps** d'un cycle de synchronisation, et ses gardes.
///
/// ## Pourquoi une classe à part
///
/// `SyncStatusCubit` faisait deux métiers : projeter un état sur une pastille,
/// et exécuter la séquence `flush → révocation → pull` avec les trois gardes
/// qui la protègent. Le second a doublé de taille en trois lots (battement,
/// cycle complet, estampilles) et noyait le premier. Ce qui vit ici est ce qui
/// **agit** ; ce qui reste là-bas est ce qui **affiche**.
///
/// La frontière est nette : ce runner ne connaît ni `SyncStatus`, ni l'outbox,
/// ni le cubit. Il rend un [SyncCycleOutcome] et laisse l'appelant décider ce
/// qu'il en projette.
///
/// ## Les estampilles vivent ici
///
/// Elles sont écrites par le cycle, et lues par la politique du tic et de la
/// reprise. Les laisser au cubit obligeait à les lui faire écrire depuis un
/// code qu'il n'exécutait plus.
///
/// **Entièrement défensif**, comme le cubit dont il sort : aucun accès
/// plugin/base ne doit remonter une exception. Une garde défaillante laisse
/// passer plutôt que de geler la synchronisation — l'intercepteur de refresh et
/// le serveur restent les filets réels.
class SyncCycleRunner {
  final SyncEngine _syncEngine;
  final ConnectivityService _connectivity;
  final PullCoordinator? _pullCoordinator;
  final RevocationEvaluator? _revocationEvaluator;
  final SessionCredentialsProbe? _credentialsProbe;
  final SessionReauthenticator? _reauthenticator;
  final Clock _now;

  SyncCycleRunner({
    required SyncEngine syncEngine,
    required ConnectivityService connectivity,
    PullCoordinator? pullCoordinator,
    RevocationEvaluator? revocationEvaluator,
    SessionCredentialsProbe? credentialsProbe,
    SessionReauthenticator? reauthenticator,
    Clock now = systemClock,
  }) : _syncEngine = syncEngine,
       _connectivity = connectivity,
       _pullCoordinator = pullCoordinator,
       _revocationEvaluator = revocationEvaluator,
       _credentialsProbe = credentialsProbe,
       _reauthenticator = reauthenticator,
       _now = now;

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
  /// cache, et donc la seule que consulte [isFullCycleDue].
  int? _lastPullAtMs;

  /// Dernière tentative de cycle, pour la politique de reprise de l'appelant.
  int? get lastCycleAttemptAtMs => _lastCycleAttemptAtMs;

  /// Le cycle complet, tel que le retour réseau et l'ouverture de session le
  /// jouent (ADR-010 D-11) : **flush → évaluation de révocation → pull**.
  ///
  /// Les deux gardes de tête ne sont pas des optimisations. Une session ouverte
  /// OFFLINE peut être sans jetons (logout sans consigne, purge d'identité
  /// croisée, consigne brûlée) : flusher quand même, c'est un 401 sur CHAQUE
  /// entrée, `attempts++` jusqu'au poison `SYNC_ERROR`, sans qu'aucune écriture
  /// ne soit partie. Et une session rouverte hors ligne revient avec un access
  /// vide ou périmé : laisser la première requête métier porter le
  /// renouvellement consomme une tentative d'outbox par entrée pour un jeton
  /// mort. Mint impossible (infra, proxy, portail) → on ne tente RIEN, la file
  /// reste intacte, le prochain cycle retentera.
  ///
  /// [onSyncingStarted] est appelé une fois les gardes franchies, juste avant
  /// le premier appel réseau : c'est le seul moment où l'appelant a quelque
  /// chose à annoncer.
  Future<SyncCycleOutcome> runFullCycle({
    required bool evaluateRevocation,
    required void Function() onSyncingStarted,
  }) async {
    // Estampillé AVANT les gardes, et non après un cycle réussi (cf.
    // [_lastCycleAttemptAtMs]).
    _lastCycleAttemptAtMs = _now();
    if (!await canAuthenticate()) return SyncCycleOutcome.nothingObserved;
    if (!await ensureFreshAccess()) return SyncCycleOutcome.nothingObserved;

    onSyncingStarted();
    await _flush();

    bool revoked = false;
    if (evaluateRevocation) {
      try {
        revoked = await _revocationEvaluator?.evaluateRevocation() ?? false;
      } catch (_) {
        // evaluateRevocation ne lève pas (contrat) ; garde-fou par prudence.
      }
    }
    if (revoked) return SyncCycleOutcome.nothingObserved;

    return _pull();
  }

  /// Le push seul — même chemin que l'écriture locale et la reprise rapprochée.
  ///
  /// Hors ligne, ni le mint ni le flush n'ont de sens (le moteur no-ope de
  /// toute façon) : tenter le mint imposerait un timeout réseau à CHAQUE
  /// écriture locale, soit exactement le régime de travail hors connexion.
  ///
  /// [onSyncingStarted] est optionnel ici : un push que **personne n'a
  /// demandé** (le tic du battement) ne doit rien annoncer, sous peine de faire
  /// clignoter la pastille toutes les 45 secondes.
  Future<void> runPushOnly({void Function()? onSyncingStarted}) async {
    if (!await isOnline()) return;
    if (!await canAuthenticate()) return;
    if (!await ensureFreshAccess()) return;

    onSyncingStarted?.call();
    await _flush();
  }

  /// Le cache a-t-il assez vieilli pour mériter un cycle complet ?
  ///
  /// Deux questions, pas une. La première porte sur l'âge du **cache**
  /// ([_lastPullAtMs]) : c'est elle qui décide qu'un cycle est dû. La seconde
  /// porte sur la dernière **tentative** ([_lastCycleAttemptAtMs]) et ne sert
  /// qu'à espacer les reprises quand les cycles échouent — un portail captif
  /// laisse le cache éternellement périmé, et sans ce plancher le tic
  /// relancerait un cycle complet toutes les 45 s pour rien.
  bool isFullCycleDue() {
    final sincePull = elapsedSince(_lastPullAtMs);
    if (sincePull != null && sincePull < kFullCycleMaxAgeMs) return false;
    final sinceAttempt = elapsedSince(_lastCycleAttemptAtMs);
    return sinceAttempt == null || sinceAttempt >= kFailedCycleRetryMs;
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
  int? elapsedSince(int? stampMs) {
    if (stampMs == null) return null;
    final elapsed = _now() - stampMs;
    return elapsed < 0 ? null : elapsed;
  }

  /// Défensif : une plateforme sans `connectivity_plus` (tests) ne doit pas
  /// geler la synchro — on suppose alors « en ligne ».
  Future<bool> isOnline() async {
    try {
      return await _connectivity.isOnline();
    } catch (_) {
      return true;
    }
  }

  /// Sans sonde branchée (tests, plateformes partielles) : pas de gate.
  Future<bool> canAuthenticate() async {
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
  Future<bool> ensureFreshAccess() async {
    final reauth = _reauthenticator;
    if (reauth == null) return true;
    try {
      return await reauth.ensureFreshAccess();
    } catch (_) {
      return true; // ne pas geler la synchro sur une défaillance de la sonde
    }
  }

  Future<void> _flush() async {
    try {
      await _syncEngine.flush();
    } catch (_) {
      // flush() encapsule déjà ses erreurs ; garde-fou par prudence.
    }
  }

  Future<SyncCycleOutcome> _pull() async {
    try {
      final report = await _pullCoordinator?.pullAll();
      // L'âge du cache n'avance QUE sur un cycle qui a réellement observé
      // quelque chose. Un rapport `skipped` (cycle déjà en vol) ou `offline` ne
      // dit rien, et le compter pour frais figerait le référentiel pour un
      // quart d'heure de plus. Aucun coordinateur branché : il n'y a rien à
      // tirer, donc rien qui puisse vieillir.
      if (report == null) {
        _lastPullAtMs = _now();
        return SyncCycleOutcome.nothingObserved;
      }
      if (report.skipped || report.offline) {
        return SyncCycleOutcome(latestServerTimeMs: report.latestServerTimeMs);
      }
      _lastPullAtMs = _now();
      return SyncCycleOutcome(
        pullDegraded: report.isDegraded,
        pullRetriable: report.failed > 0,
        latestServerTimeMs: report.latestServerTimeMs,
      );
    } catch (_) {
      // pullAll() encapsule déjà ses erreurs ; garde-fou par prudence.
      return SyncCycleOutcome.nothingObserved;
    }
  }
}
