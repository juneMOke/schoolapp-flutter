import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/revocation_evaluator.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
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
/// Sert aussi de colle du « sync loop » : à chaque passage à *online* il
/// déclenche un flush opportuniste de l'outbox **puis un pull delta**
/// ([PullCoordinator], optionnel) des ressources de référence — aucun autre
/// déclencheur global n'existe. Les écrans qui écrivent en local appellent
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
  final SyncMetaDao _syncMetaDao;

  /// Clé `sync_meta` sentinelle (ne correspond à aucune ressource métier) où
  /// est persistée la date de dernière synchro globale (badge top bar).
  static const String _kGlobalLastSyncResource = '__global_last_sync__';

  /// Epoch ms **heure serveur** de la dernière synchro connue — hydraté au
  /// démarrage depuis `sync_meta`, avancé uniquement par un pull réussi avec
  /// données (jamais régressé par un simple changement de [SyncStatus]).
  int? _lastSyncAtMs;

  StreamSubscription<bool>? _connectivitySub;

  SyncStatusCubit({
    required OutboxDao outbox,
    required ConnectivityService connectivity,
    required SyncEngine syncEngine,
    required SyncMetaDao syncMetaDao,
    PullCoordinator? pullCoordinator,
    RevocationEvaluator? revocationEvaluator,
    SessionCredentialsProbe? credentialsProbe,
  }) : _outbox = outbox,
       _connectivity = connectivity,
       _syncEngine = syncEngine,
       _syncMetaDao = syncMetaDao,
       _pullCoordinator = pullCoordinator,
       _revocationEvaluator = revocationEvaluator,
       _credentialsProbe = credentialsProbe,
       super(const SyncStatusState(status: SyncStatus.synced)) {
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
  Future<void> _syncOnReconnect() async {
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
    _safeEmit(SyncStatus.syncing);
    try {
      await _syncEngine.flush();
    } catch (_) {
      // flush() encapsule déjà ses erreurs ; garde-fou par prudence.
    }
    bool revoked = false;
    try {
      revoked = await _revocationEvaluator?.evaluateRevocation() ?? false;
    } catch (_) {
      // evaluateRevocation ne lève pas (contrat) ; garde-fou par prudence.
    }
    if (!revoked) {
      try {
        final report = await _pullCoordinator?.pullAll();
        final observed = report?.latestServerTimeMs;
        if (observed != null) await _advanceLastSync(observed);
      } catch (_) {
        // pullAll() encapsule déjà ses erreurs ; garde-fou par prudence.
      }
    }
    await refresh();
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
      if (await _outbox.errorCount() > 0) {
        _safeEmit(SyncStatus.syncConflict);
        return;
      }
      _safeEmit(pending > 0 ? SyncStatus.pendingUpload : SyncStatus.synced);
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

  /// À appeler après une écriture locale (write-path) réussie : reflète
  /// immédiatement la file d'attente, puis tente un push opportuniste en fond.
  Future<void> notifyLocalWrite() async {
    await refresh();
    unawaited(_flushAndRefresh());
  }

  Future<void> _flushAndRefresh() async {
    // Même gate que le reconnect : sans crédentiels, le push opportuniste
    // post-écriture ne ferait que consommer des tentatives en 401.
    if (!await _canAuthenticate()) {
      await refresh();
      return;
    }
    _safeEmit(SyncStatus.syncing);
    try {
      await _syncEngine.flush();
    } catch (_) {
      // flush() encapsule déjà ses erreurs ; garde-fou par prudence.
    }
    await refresh();
  }

  void _safeEmit(SyncStatus status) {
    if (isClosed) return;
    final next = SyncStatusState(status: status, lastSyncAtMs: _lastSyncAtMs);
    if (state != next) emit(next);
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _unsubscribeFlush?.call();
    return super.close();
  }
}
