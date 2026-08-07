import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_member_pull_api.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_member_pull_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_member_pull_repository.dart';

/// Clé `sync_meta` du curseur de pull du roster.
const String kClassroomMembersResource = 'classroom_members';

/// Page keyset incohérente : `hasMore` annoncé sans curseur qui progresse.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Issue d'un cycle + le seul signal exploitable par un rejeu (un curseur 400
/// est dissoluble par bootstrap).
class _CycleAttempt {
  final Either<Failure, ClassroomMemberPullOutcome> result;
  final bool rejectedCursor;
  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pull KEYSET du roster (CF2, re-contracté 2026-07-27) — miroir *lecture* de
/// `SPEC_Frontend_Classroom_Offline_V1` (`GET /sync/classroom-members`).
/// Ressource **indépendante** des classes (curseur séparé) : un flux peut
/// avoir plusieurs pages à tirer pendant que l'autre est déjà à jour, sans
/// synchro artificielle. Jeton opaque mémorisé à CHAQUE page (`nextCursor` =
/// progression → reprise après coupure), remplacé par `nextWatermark` en fin
/// de cycle. Calque exact de `ClassroomTransferPullRepositoryImpl`.
class ClassroomMemberPullRepositoryImpl
    implements ClassroomMemberPullRepository {
  final ClassroomMemberPullApi _api;
  final ClassroomLocalDataSource _localDataSource;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  static const String resource = kClassroomMembersResource;
  static const int pageLimit = 100;

  ClassroomMemberPullRepositoryImpl({
    required ClassroomMemberPullApi api,
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
  Future<Either<Failure, ClassroomMemberPullOutcome>>? _tail;

  @override
  Future<Either<Failure, ClassroomMemberPullOutcome>> syncMembers({
    required String academicYearId,
  }) {
    final prev = _tail;
    late final Future<Either<Failure, ClassroomMemberPullOutcome>> scheduled;
    final run = prev == null
        ? _pull(academicYearId)
        : prev.then((_) => _pull(academicYearId));
    scheduled = run.whenComplete(() {
      if (identical(_tail, scheduled)) _tail = null;
    });
    _tail = scheduled;
    return scheduled;
  }

  Future<Either<Failure, ClassroomMemberPullOutcome>> _pull(
    String academicYearId,
  ) async {
    final syncedAt = _now();
    final stored = await _syncMetaDao.getCursor(resource); // null = bootstrap
    final first = await _attemptCycle(syncedAt, academicYearId, from: stored);
    // 400 = curseur illisible / forgé / étranger → repartir du bootstrap. Hors
    // du `catch` : une exception dans un `catch` s'échapperait de `_pull` qui
    // promet de ne jamais lever.
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      return (await _attemptCycle(syncedAt, academicYearId, from: null)).result;
    }
    return first.result;
  }

  Future<_CycleAttempt> _attemptCycle(
    int syncedAt,
    String academicYearId, {
    required String? from,
  }) async {
    try {
      return _CycleAttempt(
        Right(await _runCycle(syncedAt, academicYearId, from: from)),
      );
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
          Right(ClassroomMemberPullOutcome.notModifiedAt(syncedAt, kept)),
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
        Left(ServerFailure('Invalid classroom-members pull payload')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  Future<ClassroomMemberPullOutcome> _runCycle(
    int syncedAt,
    String academicYearId, {
    required String? from,
  }) async {
    var cursor = from;
    var upserted = 0;
    String? lastServerTime;
    while (true) {
      final sent = cursor;
      final response = await _api.pullMembers(
        _requiredAuth,
        sent,
        pageLimit,
        academicYearId,
      );
      final data = response.data;
      lastServerTime = data.page.serverTime;
      await _localDataSource.upsertMembers(
        members: data.items,
        syncedAt: syncedAt,
      );
      upserted += data.items.length;

      final nextToken = data.page.cursorToPersist;
      if (nextToken != null) cursor = nextToken;
      await _syncMetaDao.setCursor(
        resource,
        cursor: cursor,
        syncedAt: syncedAt,
      );

      if (!data.page.hasMore) break; // dernière page du cycle
      // Anti-boucle : keyset strictement croissant → `hasMore` sans curseur qui
      // avance = serveur défaillant. On LÈVE (sortir en silence bloquerait la
      // tablette en la comptant synchronisée).
      if (data.page.nextCursor == null || data.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    return upserted == 0
        ? ClassroomMemberPullOutcome.notModifiedAt(syncedAt, cursor)
        : ClassroomMemberPullOutcome(
            upserted: upserted,
            notModified: false,
            syncedAt: syncedAt,
            cursor: cursor,
            serverTimeMs: EpochIsoHelper.tryToEpochMs(lastServerTime),
          );
  }
}
