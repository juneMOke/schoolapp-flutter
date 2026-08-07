import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_pull_api.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/attendance_pull_outcome.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_pull_repository.dart';

/// Clé `sync_meta` du curseur de pull de la Présence.
const String kAttendanceResource = 'attendance';

/// Clé `sync_meta` du drapeau bootstrapComplete (cursor non nul = complété).
/// Prérequis des statistiques (invariant #7), lu aussi par le repo de lecture.
const String kAttendanceBootstrapResource = 'attendance_bootstrap';

/// Page keyset incohérente : `hasMore` annoncé sans curseur qui progresse — le
/// serveur nous ferait rejouer la même page indéfiniment.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Issue d'un cycle : le résultat traduit + le seul signal exploitable par un
/// rejeu (un curseur 400 est dissoluble par bootstrap, rien d'autre ne l'est).
class _CycleAttempt {
  final Either<Failure, AttendancePullOutcome> result;
  final bool rejectedCursor;
  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pull KEYSET de la Présence — miroir *lecture* de `openapi_attendance_sync.yaml`
/// (`GET /sync/attendance`, ADR-008/009). Une ressource cadrée à l'année, paginée
/// keyset et **résumable** : le jeton opaque est mémorisé à CHAQUE page
/// (`nextCursor` = progression → reprise après coupure), puis remplacé par le
/// `nextWatermark` en fin de cycle (safety lag Δ déjà appliqué serveur).
///
/// Un cycle qui atteint `hasMore=false` pose le drapeau **bootstrapComplete**
/// (`sync_meta[bootstrapResource]`) : prérequis des statistiques (invariant #7).
class AttendancePullRepositoryImpl implements AttendancePullRepository {
  final AttendancePullApi _api;
  final AttendanceLocalDataSource _localDataSource;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  /// Clé `sync_meta` du curseur de pull.
  static const String resource = kAttendanceResource;

  /// Clé `sync_meta` du drapeau bootstrapComplete (cursor non nul = complété).
  static const String bootstrapResource = kAttendanceBootstrapResource;

  static const int pageLimit = 100;

  AttendancePullRepositoryImpl({
    required AttendancePullApi api,
    required AttendanceLocalDataSource localDataSource,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _localDataSource = localDataSource,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _now = now;

  /// Sérialise les cycles : un cycle en vol chaîne le suivant (deux cycles
  /// concurrents liraient le même jeton de départ et rembobineraient le curseur).
  Future<Either<Failure, AttendancePullOutcome>>? _tail;

  @override
  Future<Either<Failure, AttendancePullOutcome>> syncAttendance() {
    final prev = _tail;
    late final Future<Either<Failure, AttendancePullOutcome>> scheduled;
    final run = prev == null ? _pull() : prev.then((_) => _pull());
    scheduled = run.whenComplete(() {
      if (identical(_tail, scheduled)) _tail = null;
    });
    _tail = scheduled;
    return scheduled;
  }

  Future<Either<Failure, AttendancePullOutcome>> _pull() async {
    final syncedAt = _now();
    final stored = await _syncMetaDao.getCursor(resource); // null = bootstrap
    final first = await _attemptCycle(syncedAt, from: stored);
    // 400 = curseur illisible / forgé / étranger → repartir du bootstrap. Hors
    // du `catch` : une exception dans un `catch` s'échapperait de `_pull` qui
    // promet de ne jamais lever (l'appelant est un `unawaited`).
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
        // Rien de neuf : jeton conservé (relu, pas réécrit depuis `from` — un 304
        // peut tomber en cours de cycle après une progression déjà persistée).
        final kept = await _syncMetaDao.getCursor(resource);
        await _syncMetaDao.setCursor(
          resource,
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _CycleAttempt(
          Right(
            AttendancePullOutcome.notModifiedAt(
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
        Left(ServerFailure('Invalid attendance pull payload')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  Future<AttendancePullOutcome> _runCycle(
    int syncedAt, {
    required String? from,
  }) async {
    var cursor = from;
    var upserted = 0;
    var reachedEnd = false;
    String? lastServerTime;
    while (true) {
      final sent = cursor;
      final response = await _api.pullAttendance(
        _requiredAuth,
        sent,
        pageLimit,
        null, // academicYearId : défaut serveur = année active
        null, // classroomId : pull de masse
      );
      final data = response.data;
      lastServerTime = data.page.serverTime;
      upserted += await _localDataSource.applyPulledSessions(
        data.items.map((d) => d.toPulled(syncedAt)).toList(),
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
        ? AttendancePullOutcome.notModifiedAt(
            syncedAt,
            cursor,
            bootstrapComplete: bootstrapComplete,
          )
        : AttendancePullOutcome(
            upserted: upserted,
            notModified: false,
            bootstrapComplete: bootstrapComplete,
            syncedAt: syncedAt,
            cursor: cursor,
            serverTimeMs: EpochIsoHelper.tryToEpochMs(lastServerTime),
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
