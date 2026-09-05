import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_pull_api.dart';

/// Clé `sync_meta` du curseur des retraits.
const String kTombstonesResource = 'sync_tombstones';

/// Le serveur ne peut plus garantir la liste des disparitions depuis ce curseur.
const String kResyncRequired = 'RESYNC_REQUIRED';

/// Page keyset incohérente : `hasMore` annoncé sans curseur qui progresse.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Issue d'un cycle de retraits.
class TombstonePullOutcome {
  final int removed;
  final int deferred;
  final bool notModified;
  final String? error;

  const TombstonePullOutcome({
    this.removed = 0,
    this.deferred = 0,
    this.notModified = false,
    this.error,
  });
}

/// Pull KEYSET du registre des disparitions.
///
/// ## Ce que fait un `410`
///
/// Le serveur refuse un curseur plus ancien que la rétention du registre : au
/// delà, la purge a pu emporter des retraits que ce poste n'a jamais vus, et lui
/// servir un delta serait lui affirmer « voici tout ce qui a disparu depuis »,
/// ce qui serait faux. La réponse est d'oublier le curseur et de rejouer tout ce
/// que le registre garde encore.
///
/// **Ce rattrapage a une limite, et il faut la nommer** : les lignes supprimées
/// AVANT la fenêtre de rétention n'ont plus de pierre tombale, et aucun rejeu ne
/// les fera réapparaître. Les effacer demanderait une réhydratation complète des
/// flux de données eux-mêmes, décision qui n'appartient pas à ce dépôt. Le cas
/// suppose une tablette restée plus de trois mois hors ligne — c'est-à-dire, en
/// pratique, une rentrée scolaire.
class TombstonePullRepository {
  final TombstonePullApi _api;
  final TombstoneDao _dao;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  static const String resource = kTombstonesResource;
  static const int pageLimit = 200;

  TombstonePullRepository({
    required TombstonePullApi api,
    required TombstoneDao dao,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _now = now;

  /// Sérialise les cycles : deux cycles concurrents rembobineraient le curseur.
  Future<TombstonePullOutcome>? _tail;

  Future<TombstonePullOutcome> sync() {
    final prev = _tail;
    late final Future<TombstonePullOutcome> scheduled;
    final run = prev == null ? _pull() : prev.then((_) => _pull());
    scheduled = run.whenComplete(() {
      if (identical(_tail, scheduled)) _tail = null;
    });
    _tail = scheduled;
    return scheduled;
  }

  Future<TombstonePullOutcome> _pull() async {
    final syncedAt = _now();
    final stored = await _syncMetaDao.getCursor(resource); // null = bootstrap
    final first = await _attemptCycle(syncedAt, from: stored);
    // 400 : curseur illisible ou étranger. 410 : curseur plus ancien que la
    // rétention. Les deux se traitent pareil — oublier le jeton et repartir du
    // début — mais pour des raisons opposées, et le journal doit les distinguer.
    if (first.restartFromScratch && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      return (await _attemptCycle(syncedAt, from: null)).outcome;
    }
    return first.outcome;
  }

  Future<_CycleAttempt> _attemptCycle(
    int syncedAt, {
    required String? from,
  }) async {
    try {
      return _CycleAttempt(await _runCycle(syncedAt, from: from));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        final kept = await _syncMetaDao.getCursor(resource);
        await _syncMetaDao.setCursor(
          resource,
          cursor: kept,
          syncedAt: syncedAt,
        );
        return const _CycleAttempt(TombstonePullOutcome(notModified: true));
      }
      if (status == 410) {
        return const _CycleAttempt(
          TombstonePullOutcome(error: kResyncRequired),
          restartFromScratch: true,
        );
      }
      return _CycleAttempt(
        TombstonePullOutcome(error: e.message ?? e.toString()),
        restartFromScratch: status == 400,
      );
    } on _IncoherentKeysetPage catch (_) {
      return const _CycleAttempt(
        TombstonePullOutcome(
          error: 'Incoherent keyset page: hasMore without a cursor',
        ),
      );
    } catch (e) {
      return _CycleAttempt(TombstonePullOutcome(error: e.toString()));
    }
  }

  Future<TombstonePullOutcome> _runCycle(
    int syncedAt, {
    required String? from,
  }) async {
    var cursor = from;
    var removed = 0;
    var deferred = 0;
    var applied = 0;
    while (true) {
      final sent = cursor;
      final response = await _api.pullTombstones(
        _requiredAuth,
        sent,
        pageLimit,
      );
      final data = response.data;

      final result = await _dao.apply(data.items);
      removed += result.removed;
      deferred += result.deferred;
      applied += data.items.length;

      final nextToken = data.page.cursorToPersist;
      if (nextToken != null) cursor = nextToken;
      // Le jeton est mémorisé à CHAQUE page : une coupure reprend là où elle a
      // laissé, et les retraits déjà appliqués ne sont pas rejoués.
      await _syncMetaDao.setCursor(
        resource,
        cursor: cursor,
        syncedAt: syncedAt,
      );

      if (!data.page.hasMore) break;
      // Anti-boucle : keyset strictement croissant → `hasMore` sans curseur qui
      // avance est un serveur défaillant. On lève plutôt que de tourner en rond.
      if (data.page.nextCursor == null || data.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    return TombstonePullOutcome(
      removed: removed,
      deferred: deferred,
      // Un cycle qui a reçu des retraits n'est pas « non modifié », même si
      // aucun ne visait une ligne que ce poste détenait : le curseur a avancé.
      notModified: applied == 0,
    );
  }
}

class _CycleAttempt {
  final TombstonePullOutcome outcome;
  final bool restartFromScratch;

  const _CycleAttempt(this.outcome, {this.restartFromScratch = false});
}
