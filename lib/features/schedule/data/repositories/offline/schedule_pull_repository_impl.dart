import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/owner_scope.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_pull_api.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/schedule_pull_models.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/offline/ref_pull_outcome.dart';

/// Clés `sync_meta` des curseurs et drapeaux bootstrapComplete des deux
/// ressources de référence de l'emploi du temps (curseurs **indépendants**).
const String kScheduleTimeSlotsResource = 'schedule_time_slots';
const String kScheduleTimeSlotsBootstrap = 'schedule_time_slots_bootstrap';
const String kScheduleSessionsResource = 'schedule_sessions';
const String kScheduleSessionsBootstrap = 'schedule_sessions_bootstrap';

/// Page keyset incohérente : `hasMore` annoncé sans curseur qui progresse — le
/// serveur nous ferait rejouer la même page indéfiniment.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Issue d'un cycle : résultat traduit + le seul signal exploitable par un rejeu
/// (un curseur 400 est dissoluble par bootstrap, rien d'autre ne l'est).
class _CycleAttempt {
  final Either<Failure, RefPullOutcome> result;
  final bool rejectedCursor;
  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pull KEYSET des tables de **référence** de l'emploi du temps (time-slots,
/// sessions) — miroir *lecture* du contrat `GET /sync/schedule/*` (ADR-008/009).
/// Paginé keyset et **résumable** : le jeton opaque est mémorisé à CHAQUE page
/// (progression → reprise après coupure), puis remplacé par le `nextWatermark`
/// en fin de cycle (safety lag Δ déjà appliqué serveur).
///
/// Money-grade : ne **lève jamais** (échec encodé en `Left`). Les deux
/// ressources ont des curseurs et des drapeaux bootstrap **indépendants** et
/// leurs cycles sont sérialisés séparément.
///
/// **Partition par compte** : les séances étant cadrées enseignant, leur
/// curseur est scopé par `uid` (cf. `core/offline/owner_scope.dart`) — sans
/// ça, le second prof d'une tablette partagée reprendrait le curseur du
/// premier et recevrait un `304` au lieu de ses propres séances. Les créneaux,
/// référentiel d'école, gardent un curseur unique.
class SchedulePullRepositoryImpl {
  final SchedulePullApi _api;
  final ScheduleRefLocalDataSource _local;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final CurrentUserContext? _currentUser;
  final Clock _now;

  static const int pageLimit = 100;

  SchedulePullRepositoryImpl({
    required SchedulePullApi api,
    required ScheduleRefLocalDataSource localDataSource,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    CurrentUserContext? currentUser,
    Clock now = systemClock,
  }) : _api = api,
       _local = localDataSource,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _currentUser = currentUser,
       _now = now;

  /// Compte au nom duquel le cycle courant tire — lu au DÉBUT de chaque cycle
  /// et transporté jusqu'à l'écriture, pour qu'une déconnexion en cours de
  /// pagination n'estampille pas la fin d'un delta sous un autre propriétaire.
  String? get _ownerUid => _currentUser?.uid;

  Future<Either<Failure, RefPullOutcome>>? _timeSlotsTail;
  Future<Either<Failure, RefPullOutcome>>? _sessionsTail;

  /// Pull des créneaux horaires (scope école, JWT).
  Future<Either<Failure, RefPullOutcome>> syncTimeSlots() {
    late final Future<Either<Failure, RefPullOutcome>> scheduled;
    final prev = _timeSlotsTail;
    Future<Either<Failure, RefPullOutcome>> run() => _pull<TimeSlotDeltaDto>(
      resource: kScheduleTimeSlotsResource,
      bootstrapResource: kScheduleTimeSlotsBootstrap,
      fetchPage: (cursor) async =>
          (await _api.pullTimeSlots(_requiredAuth, cursor, pageLimit)).data,
      apply: (page, syncedAt) => _local.applyPulledTimeSlots(
        page.items.map((d) => d.toLocalRow(syncedAt)).toList(),
      ),
    );
    final future = prev == null ? run() : prev.then((_) => run());
    scheduled = future.whenComplete(() {
      if (identical(_timeSlotsTail, scheduled)) _timeSlotsTail = null;
    });
    _timeSlotsTail = scheduled;
    return scheduled;
  }

  /// Pull des séances récurrentes de l'enseignant connecté (scope **prof
  /// dérivé du token** + année active — commit back `1ec6be3`, DF-K). `404` =
  /// compte non lié à un enseignant.
  Future<Either<Failure, RefPullOutcome>> syncSessions() {
    late final Future<Either<Failure, RefPullOutcome>> scheduled;
    final prev = _sessionsTail;
    Future<Either<Failure, RefPullOutcome>> run() {
      // Propriétaire figé pour tout le cycle (cf. `_ownerUid`).
      final owner = _ownerUid;
      return _pull<RecurringSessionDeltaDto>(
        resource: scopedResource(kScheduleSessionsResource, owner),
        bootstrapResource: scopedResource(kScheduleSessionsBootstrap, owner),
        treat404AsNotModified: true,
        fetchPage: (cursor) async => (await _api.pullSessions(
          _requiredAuth,
          cursor,
          pageLimit,
          null,
        )).data,
        apply: (page, syncedAt) => _local.applyPulledSessions(
          page.items.map((d) => d.toLocalRow(syncedAt)).toList(),
          ownerUid: owner,
        ),
      );
    }

    final future = prev == null ? run() : prev.then((_) => run());
    scheduled = future.whenComplete(() {
      if (identical(_sessionsTail, scheduled)) _sessionsTail = null;
    });
    _sessionsTail = scheduled;
    return scheduled;
  }

  /// Squelette de pull keyset générique, partagé par les deux ressources.
  /// [treat404AsNotModified] : la ressource peut légitimement renvoyer `404`
  /// pour un compte non lié à un enseignant (sessions, DF-K) — traité comme un
  /// cycle à jour, jamais une erreur. Non pertinent pour les créneaux (scope
  /// école, sans notion d'enseignant).
  Future<Either<Failure, RefPullOutcome>> _pull<I>({
    required String resource,
    required String bootstrapResource,
    required Future<KeysetPageDto<I>> Function(String? cursor) fetchPage,
    required Future<int> Function(KeysetPageDto<I> page, int syncedAt) apply,
    bool treat404AsNotModified = false,
  }) async {
    final syncedAt = _now();
    final stored = await _syncMetaDao.getCursor(resource); // null = bootstrap
    final first = await _attemptCycle<I>(
      syncedAt,
      from: stored,
      resource: resource,
      bootstrapResource: bootstrapResource,
      fetchPage: fetchPage,
      apply: apply,
      treat404AsNotModified: treat404AsNotModified,
    );
    // 400 = curseur illisible / forgé / étranger → repartir du bootstrap. Hors
    // du `catch` (une exception dans un `catch` s'échapperait de `_pull` qui
    // promet de ne jamais lever).
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      return (await _attemptCycle<I>(
        syncedAt,
        from: null,
        resource: resource,
        bootstrapResource: bootstrapResource,
        fetchPage: fetchPage,
        apply: apply,
        treat404AsNotModified: treat404AsNotModified,
      )).result;
    }
    return first.result;
  }

  Future<_CycleAttempt> _attemptCycle<I>(
    int syncedAt, {
    required String? from,
    required String resource,
    required String bootstrapResource,
    required Future<KeysetPageDto<I>> Function(String? cursor) fetchPage,
    required Future<int> Function(KeysetPageDto<I> page, int syncedAt) apply,
    bool treat404AsNotModified = false,
  }) async {
    try {
      return _CycleAttempt(
        Right(
          await _runCycle<I>(
            syncedAt,
            from: from,
            resource: resource,
            bootstrapResource: bootstrapResource,
            fetchPage: fetchPage,
            apply: apply,
          ),
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304 || (status == 404 && treat404AsNotModified)) {
        final kept = await _syncMetaDao.getCursor(resource);
        await _syncMetaDao.setCursor(
          resource,
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _CycleAttempt(
          Right(
            RefPullOutcome.notModifiedAt(
              syncedAt,
              kept,
              bootstrapComplete: await _isBootstrapComplete(bootstrapResource),
            ),
          ),
        );
      }
      return _CycleAttempt(
        Left(ServerFailure(e.message ?? e.toString())),
        rejectedCursor: status == 400,
      );
    } on _IncoherentKeysetPage catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Incoherent keyset page: hasMore without a cursor')),
      );
    } on FormatException catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Invalid schedule pull payload')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  Future<RefPullOutcome> _runCycle<I>(
    int syncedAt, {
    required String? from,
    required String resource,
    required String bootstrapResource,
    required Future<KeysetPageDto<I>> Function(String? cursor) fetchPage,
    required Future<int> Function(KeysetPageDto<I> page, int syncedAt) apply,
  }) async {
    var cursor = from;
    var upserted = 0;
    var reachedEnd = false;
    String? lastServerTime;
    while (true) {
      final sent = cursor;
      final page = await fetchPage(sent);
      lastServerTime = page.page.serverTime;
      upserted += await apply(page, syncedAt);

      final nextToken = page.page.cursorToPersist;
      if (nextToken != null) cursor = nextToken;
      await _syncMetaDao.setCursor(
        resource,
        cursor: cursor,
        syncedAt: syncedAt,
      );

      if (!page.page.hasMore) {
        reachedEnd = true;
        break;
      }
      // Anti-boucle : keyset strictement croissant → `hasMore` sans curseur qui
      // avance = serveur défaillant. On LÈVE (sortir en silence compterait la
      // ressource comme synchronisée).
      if (page.page.nextCursor == null || page.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    if (reachedEnd) await _markBootstrapComplete(bootstrapResource, syncedAt);
    final bootstrapComplete = await _isBootstrapComplete(bootstrapResource);

    return upserted == 0
        ? RefPullOutcome.notModifiedAt(
            syncedAt,
            cursor,
            bootstrapComplete: bootstrapComplete,
          )
        : RefPullOutcome(
            upserted: upserted,
            notModified: false,
            bootstrapComplete: bootstrapComplete,
            syncedAt: syncedAt,
            cursor: cursor,
            serverTimeMs: EpochIsoHelper.tryToEpochMs(lastServerTime),
          );
  }

  Future<bool> _isBootstrapComplete(String bootstrapResource) async =>
      (await _syncMetaDao.getCursor(bootstrapResource)) != null;

  Future<void> _markBootstrapComplete(String bootstrapResource, int syncedAt) =>
      _syncMetaDao.setCursor(
        bootstrapResource,
        cursor: 'DONE',
        syncedAt: syncedAt,
      );
}
