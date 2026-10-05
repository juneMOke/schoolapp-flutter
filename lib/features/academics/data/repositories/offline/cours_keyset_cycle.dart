import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';

/// Une page d'un flux scopé cours.
typedef CoursPageFetcher<I> =
    Future<KeysetPageDto<I>> Function(String coursId, String? cursor);

/// Applique une page en local ; rend le nombre de lignes écrites.
typedef CoursPageApplier<I> =
    Future<int> Function(KeysetPageDto<I> page, int syncedAt);

/// Code du 403 qui dit « ce cours n'est plus à toi » — le seul qui évince.
const String kCoursNotOwnedCode = 'COURS_NOT_OWNED';

/// Le 403 d'un cours réaffecté. Un autre 403 (permission absente d'un jeton
/// pas encore renouvelé) n'est qu'un échec : évincer sur lui retirerait ses
/// cours à un professeur qui n'a fait que ne pas se reconnecter.
bool isCoursNotOwned(DioException e) =>
    e.response?.statusCode == 403 &&
    ApiErrorParser.detailCodeOf(e.response) == kCoursNotOwnedCode;

class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Ce qu'un cycle a fait pour un cours.
class CoursCycleResult {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  final int? serverTimeMs;
  const CoursCycleResult({
    required this.upserted,
    required this.notModified,
    required this.bootstrapComplete,
    this.serverTimeMs,
  });
}

class _CycleAttempt {
  final Either<Failure, CoursCycleResult> result;
  final bool rejectedCursor;
  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Le tirage d'**un** cours pour une ressource : pages jusqu'au bout, curseur
/// rangé après chaque page, fin de bootstrap notée. Un 304 garde le curseur ;
/// un 403 `COURS_NOT_OWNED` évince le cours ; un 400 rejette le curseur.
class CoursKeysetCycle {
  final SyncMetaDao _syncMetaDao;
  final CoursEviction _eviction;

  const CoursKeysetCycle({
    required SyncMetaDao syncMetaDao,
    required CoursEviction eviction,
  }) : _syncMetaDao = syncMetaDao,
       _eviction = eviction;

  /// Un cycle complet pour [coursId], rebootstrapé une fois si le serveur
  /// refuse le curseur rangé (400).
  Future<Either<Failure, CoursCycleResult>> run<I>(
    String resourcePrefix,
    String coursId,
    int syncedAt,
    CoursPageFetcher<I> fetchPage,
    CoursPageApplier<I> apply,
  ) async {
    final resource = '$resourcePrefix:$coursId';
    final stored = await _syncMetaDao.getCursor(resource);
    final first = await _attemptCycle<I>(
      resourcePrefix,
      coursId,
      syncedAt,
      from: stored,
      fetchPage: fetchPage,
      apply: apply,
    );
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      return (await _attemptCycle<I>(
        resourcePrefix,
        coursId,
        syncedAt,
        from: null,
        fetchPage: fetchPage,
        apply: apply,
      )).result;
    }
    return first.result;
  }

  Future<_CycleAttempt> _attemptCycle<I>(
    String resourcePrefix,
    String coursId,
    int syncedAt, {
    required String? from,
    required CoursPageFetcher<I> fetchPage,
    required CoursPageApplier<I> apply,
  }) async {
    final resource = '$resourcePrefix:$coursId';
    final bootstrapResource = '${resourcePrefix}_bootstrap:$coursId';
    try {
      return _CycleAttempt(
        Right(
          await _runCycle<I>(
            resourcePrefix,
            coursId,
            syncedAt,
            from: from,
            fetchPage: fetchPage,
            apply: apply,
          ),
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        final kept = await _syncMetaDao.getCursor(resource);
        await _syncMetaDao.setCursor(
          resource,
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _CycleAttempt(
          Right(
            CoursCycleResult(
              upserted: 0,
              notModified: true,
              bootstrapComplete: await _isBootstrapComplete(bootstrapResource),
            ),
          ),
        );
      }
      if (isCoursNotOwned(e)) {
        // Cours réaffecté : éviction non fatale, cycle réputé à jour pour ce
        // cours — les autres cours du batch continuent.
        await _eviction.evict(coursId);
        return const _CycleAttempt(
          Right(
            CoursCycleResult(
              upserted: 0,
              notModified: true,
              bootstrapComplete: true,
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
        Left(ServerFailure('Invalid academics delta payload')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  Future<CoursCycleResult> _runCycle<I>(
    String resourcePrefix,
    String coursId,
    int syncedAt, {
    required String? from,
    required CoursPageFetcher<I> fetchPage,
    required CoursPageApplier<I> apply,
  }) async {
    final resource = '$resourcePrefix:$coursId';
    final bootstrapResource = '${resourcePrefix}_bootstrap:$coursId';
    var cursor = from;
    var upserted = 0;
    var reachedEnd = false;
    String? lastServerTime;
    while (true) {
      final sent = cursor;
      final page = await fetchPage(coursId, sent);
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
      if (page.page.nextCursor == null || page.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    if (reachedEnd) {
      await _syncMetaDao.setCursor(
        bootstrapResource,
        cursor: 'DONE',
        syncedAt: syncedAt,
      );
    }
    return CoursCycleResult(
      upserted: upserted,
      notModified: upserted == 0,
      bootstrapComplete: await _isBootstrapComplete(bootstrapResource),
      serverTimeMs: upserted == 0
          ? null
          : EpochIsoHelper.tryToEpochMs(lastServerTime),
    );
  }

  Future<bool> _isBootstrapComplete(String bootstrapResource) async =>
      (await _syncMetaDao.getCursor(bootstrapResource)) != null;
}
