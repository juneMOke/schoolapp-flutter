import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_pull_api.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_transfer_pull_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_transfer_pull_repository.dart';

/// Clé `sync_meta` du curseur de pull des transferts.
const String kClassroomTransfersResource = 'classroom_transfers';

/// Clé `sync_meta` du drapeau bootstrapComplete (cursor non nul = complété).
/// Prérequis du dénominateur d'assiduité par intervalles (F6).
const String kClassroomTransfersBootstrapResource =
    'classroom_transfers_bootstrap';

/// Page keyset incohérente : `hasMore` annoncé sans curseur qui progresse.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Issue d'un cycle + le seul signal exploitable par un rejeu (un curseur 400
/// est dissoluble par bootstrap).
class _CycleAttempt {
  final Either<Failure, ClassroomTransferPullOutcome> result;
  final bool rejectedCursor;
  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pull KEYSET des transferts (F5) — miroir *lecture* de
/// `openapi_classroom_sync.yaml` 1.1.0 (`GET /sync/classroom-transfers`). Une
/// ressource cadrée année, paginée keyset et **résumable** : jeton opaque
/// mémorisé à CHAQUE page (`nextCursor` = progression → reprise après coupure),
/// remplacé par `nextWatermark` en fin de cycle. Un cycle atteignant
/// `hasMore=false` pose **bootstrapComplete** (prérequis F6). Calque exact de
/// `AttendancePullRepositoryImpl`.
class ClassroomTransferPullRepositoryImpl
    implements ClassroomTransferPullRepository {
  final ClassroomTransferPullApi _api;
  final ClassroomLocalDataSource _localDataSource;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  static const String resource = kClassroomTransfersResource;
  static const String bootstrapResource = kClassroomTransfersBootstrapResource;
  static const int pageLimit = 100;

  ClassroomTransferPullRepositoryImpl({
    required ClassroomTransferPullApi api,
    required ClassroomLocalDataSource localDataSource,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _localDataSource = localDataSource,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _now = now;

  /// Sérialise les cycles : un cycle en vol chaîne le suivant (deux concurrents
  /// rembobineraient le curseur).
  Future<Either<Failure, ClassroomTransferPullOutcome>>? _tail;

  @override
  Future<Either<Failure, ClassroomTransferPullOutcome>> syncTransfers() {
    final prev = _tail;
    late final Future<Either<Failure, ClassroomTransferPullOutcome>> scheduled;
    final run = prev == null ? _pull() : prev.then((_) => _pull());
    scheduled = run.whenComplete(() {
      if (identical(_tail, scheduled)) _tail = null;
    });
    _tail = scheduled;
    return scheduled;
  }

  Future<Either<Failure, ClassroomTransferPullOutcome>> _pull() async {
    final syncedAt = _now();
    final stored = await _syncMetaDao.getCursor(resource); // null = bootstrap
    final first = await _attemptCycle(syncedAt, from: stored);
    // 400 = curseur illisible / forgé / étranger → repartir du bootstrap. Hors
    // du `catch` : une exception dans un `catch` s'échapperait de `_pull` qui
    // promet de ne jamais lever.
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      return (await _attemptCycle(syncedAt, from: null)).result;
    }
    return first.result;
  }

  Future<_CycleAttempt> _attemptCycle(
    int syncedAt, {
    required String? from,
  }) async {
    try {
      return _CycleAttempt(Right(await _runCycle(syncedAt, from: from)));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        // Rien de neuf : jeton relu (pas réécrit depuis `from` — un 304 peut
        // tomber en cours de cycle après une progression déjà persistée).
        final kept = await _syncMetaDao.getCursor(resource);
        await _syncMetaDao.setCursor(
          resource,
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _CycleAttempt(
          Right(
            ClassroomTransferPullOutcome.notModifiedAt(
              syncedAt,
              kept,
              bootstrapComplete: await _isBootstrapComplete(),
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
        Left(ServerFailure('Invalid classroom-transfers pull payload')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  Future<ClassroomTransferPullOutcome> _runCycle(
    int syncedAt, {
    required String? from,
  }) async {
    var cursor = from;
    var upserted = 0;
    var reachedEnd = false;
    while (true) {
      final sent = cursor;
      final response = await _api.pullTransfers(
        _requiredAuth,
        sent,
        pageLimit,
        null, // academicYearId : défaut serveur = année active
        null, // studentId : pull de masse
      );
      final data = response.data;
      upserted += await _localDataSource.applyPulledTransfers(
        data.items,
        syncedAt,
      );

      final nextToken = data.page.cursorToPersist;
      if (nextToken != null) cursor = nextToken;
      await _syncMetaDao.setCursor(
        resource,
        cursor: cursor,
        syncedAt: syncedAt,
      );

      if (!data.page.hasMore) {
        reachedEnd = true;
        break; // dernière page du cycle
      }
      // Anti-boucle : keyset strictement croissant → `hasMore` sans curseur qui
      // avance = serveur défaillant. On LÈVE (sortir en silence bloquerait la
      // tablette en la comptant synchronisée).
      if (data.page.nextCursor == null || data.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    if (reachedEnd) await _markBootstrapComplete(syncedAt);
    final bootstrapComplete = await _isBootstrapComplete();

    return upserted == 0
        ? ClassroomTransferPullOutcome.notModifiedAt(
            syncedAt,
            cursor,
            bootstrapComplete: bootstrapComplete,
          )
        : ClassroomTransferPullOutcome(
            upserted: upserted,
            notModified: false,
            bootstrapComplete: bootstrapComplete,
            syncedAt: syncedAt,
            cursor: cursor,
          );
  }

  Future<bool> _isBootstrapComplete() async =>
      (await _syncMetaDao.getCursor(bootstrapResource)) != null;

  Future<void> _markBootstrapComplete(int syncedAt) => _syncMetaDao.setCursor(
    bootstrapResource,
    cursor: 'DONE',
    syncedAt: syncedAt,
  );
}
