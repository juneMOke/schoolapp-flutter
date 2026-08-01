import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_state.dart';
import 'package:school_app_flutter/core/components/status/outbox_retry_policy.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/offline/outbox_author_directory.dart';
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
  final CurrentUserContext? _currentUser;
  final OutboxAuthorDirectory? _authorDirectory;

  OutboxErrorsCubit({
    required OutboxDao outbox,
    required SyncEngine syncEngine,
    CurrentUserContext? currentUser,
    OutboxAuthorDirectory? authorDirectory,
  }) : _outbox = outbox,
       _syncEngine = syncEngine,
       _currentUser = currentUser,
       _authorDirectory = authorDirectory,
       super(const OutboxErrorsState());

  /// Charge (ou recharge) les entrées terminales, puis ce qui reste en file au
  /// nom d'autres comptes.
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
      return;
    }
    await _loadOtherAuthors();
  }

  /// Agrège les écritures d'autres comptes — **strictement best-effort** et
  /// séparé de la lecture des erreurs : c'est une explication de confort, elle
  /// ne doit jamais faire basculer la feuille en échec ni masquer les erreurs
  /// de l'utilisateur, qui sont la raison d'être de l'écran.
  Future<void> _loadOtherAuthors() async {
    try {
      final me = _currentUser?.uid;
      if (me == null || me.isEmpty) return;

      final summary = summarizeOtherAuthors(await _outbox.pendingAll(), me);
      if (summary.isEmpty) {
        _safeEmit(
          state.copyWith(
            others: OtherAuthorsPending.none,
            otherAuthors: const <OutboxAuthorIdentity?>[],
          ),
        );
        return;
      }

      final directory = _authorDirectory;
      final identities = <OutboxAuthorIdentity?>[];
      for (final uid in summary.authorUids) {
        if (directory == null) {
          identities.add(null);
          continue;
        }
        try {
          identities.add(await directory.identityOf(uid));
        } catch (_) {
          // Un annuaire défaillant dégrade en formulation anonyme, il ne fait
          // pas disparaître l'information « il reste du travail d'un collègue ».
          identities.add(null);
        }
      }
      _safeEmit(state.copyWith(others: summary, otherAuthors: identities));
    } catch (_) {
      // Idem : l'agrégat est optionnel, son échec est silencieux.
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
  Future<void> _runAction(Future<void> Function() action) async {
    if (state.busy) return;
    _safeEmit(state.copyWith(busy: true));
    try {
      await action();
      await _syncEngine.flush();
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
