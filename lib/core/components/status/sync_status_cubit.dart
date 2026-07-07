import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

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
class SyncStatusCubit extends Cubit<SyncStatus> {
  final OutboxDao _outbox;
  final ConnectivityService _connectivity;
  final SyncEngine _syncEngine;
  final PullCoordinator? _pullCoordinator;

  StreamSubscription<bool>? _connectivitySub;

  SyncStatusCubit({
    required OutboxDao outbox,
    required ConnectivityService connectivity,
    required SyncEngine syncEngine,
    PullCoordinator? pullCoordinator,
  }) : _outbox = outbox,
       _connectivity = connectivity,
       _syncEngine = syncEngine,
       _pullCoordinator = pullCoordinator,
       super(SyncStatus.synced) {
    _listenConnectivity();
    unawaited(refresh());
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

  /// Au retour *online* : on POUSSE (vidage outbox) puis on TIRE (pull delta des
  /// ressources de référence) pour rafraîchir le cache local, puis on recalcule
  /// la pastille. Le pull est silencieux (304 fréquent) et **n'altère pas**
  /// l'état de synchro, qui ne reflète que la file de push.
  Future<void> _syncOnReconnect() async {
    _safeEmit(SyncStatus.syncing);
    try {
      await _syncEngine.flush();
    } catch (_) {
      // flush() encapsule déjà ses erreurs ; garde-fou par prudence.
    }
    try {
      await _pullCoordinator?.pullAll();
    } catch (_) {
      // pullAll() encapsule déjà ses erreurs ; garde-fou par prudence.
    }
    await refresh();
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
      if (await _outbox.errorCount() > 0) {
        _safeEmit(SyncStatus.syncConflict);
        return;
      }
      final pending = await _outbox.pendingCount();
      _safeEmit(pending > 0 ? SyncStatus.pendingUpload : SyncStatus.synced);
    } catch (_) {
      // Base/plugin indisponible : on n'écrase pas le dernier état connu.
    }
  }

  /// À appeler après une écriture locale (write-path) réussie : reflète
  /// immédiatement la file d'attente, puis tente un push opportuniste en fond.
  Future<void> notifyLocalWrite() async {
    await refresh();
    unawaited(_flushAndRefresh());
  }

  Future<void> _flushAndRefresh() async {
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
    if (state != status) emit(status);
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
