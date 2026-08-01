import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/outbox_retry_policy.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';

/// Pilote la feuille de reprise des écritures en échec.
///
/// `SYNC_ERROR` est un état **terminal** : ni le backoff ni un retour online ne
/// le rejouent. Sans surface de reprise, une écriture rejetée est perdue sans
/// que personne ne le sache — c'est le seul chemin qui la ramène en file.
///
/// Le rejeu est sûr par construction : chaque push porte une clé d'idempotence
/// métier (`aggregateId`) honorée par le serveur — un agrégat déjà ingéré est
/// ré-obtenu, jamais dupliqué.
class OutboxErrorsCubit extends Cubit<OutboxErrorsState> {
  final OutboxDao _outbox;
  final SyncEngine _syncEngine;

  OutboxErrorsCubit({required OutboxDao outbox, required SyncEngine syncEngine})
    : _outbox = outbox,
      _syncEngine = syncEngine,
      super(const OutboxErrorsState());

  /// Charge (ou recharge) les entrées terminales.
  Future<void> load() async {
    try {
      final entries = await _outbox.errors();
      _safeEmit(
        state.copyWith(
          status: OutboxErrorsStatus.loaded,
          entries: entries,
          busy: false,
        ),
      );
    } catch (_) {
      // Base/plugin indisponible : on n'affiche pas une liste vide trompeuse.
      _safeEmit(
        state.copyWith(status: OutboxErrorsStatus.failure, busy: false),
      );
    }
  }

  /// Remet une entrée en file puis tente un push immédiat.
  ///
  /// Refuse silencieusement un type dont le payload gelé n'est pas rejouable
  /// (cf. [canRequeueFrozenPayload]) : l'UI n'offre déjà pas le bouton, ce garde
  /// ferme le chemin programmatique.
  Future<void> retry(String id) {
    final entry = state.entries.where((e) => e.id == id).firstOrNull;
    if (entry == null || !canRequeueFrozenPayload(entry.aggregateType)) {
      return Future<void>.value();
    }
    return _runAction(() => _outbox.requeue(id));
  }

  /// Remet en file toutes les entrées **rejouables** affichées. Les autres sont
  /// laissées en erreur : « tout réessayer » ne doit jamais faire, en lot, un
  /// geste qu'on refuse à l'unité.
  Future<void> retryAll() => _runAction(() async {
    for (final entry in state.entries) {
      if (canRequeueFrozenPayload(entry.aggregateType)) {
        await _outbox.requeue(entry.id);
      }
    }
  });

  /// Verrou d'action + rechargement systématique : quel que soit le sort du
  /// flush, la liste affichée redevient le reflet exact de la base.
  Future<void> _runAction(
    Future<void> Function() action, {
    bool flush = true,
  }) async {
    if (state.busy) return;
    _safeEmit(state.copyWith(busy: true));
    try {
      await action();
      if (flush) await _syncEngine.flush();
    } catch (_) {
      // `flush()` encapsule déjà ses erreurs ; garde-fou par prudence. L'état
      // réel est relu juste après, il n'y a rien à propager ici.
    }
    await load();
  }

  void _safeEmit(OutboxErrorsState next) {
    if (isClosed) return;
    if (state != next) emit(next);
  }
}
