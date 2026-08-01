import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

/// Préfixes `sync_meta` (curseur + bootstrap) **par cours** des deux ressources
/// métier — clés effectives `academics_evaluations:{coursId}` et
/// `academics_notes:{coursId}`. Curseurs INDÉPENDANTS (split).
const String kAcademicsEvaluationsResourcePrefix = 'academics_evaluations';
const String kAcademicsNotesResourcePrefix = 'academics_notes';

class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

class _CourseCycle {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  final int? serverTimeMs;
  const _CourseCycle({
    required this.upserted,
    required this.notModified,
    required this.bootstrapComplete,
    this.serverTimeMs,
  });
}

class _CycleAttempt {
  final Either<Failure, _CourseCycle> result;
  final bool rejectedCursor;
  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pull KEYSET métier (évaluations, notes), **itéré par cours** (les cours sont
/// lus dans `ref_cours`, peuplée par le pull cours scopé enseignant — DF-K).
/// Chaque cours a un **curseur keyset propre** par ressource. Résumable, 304,
/// 400→rebootstrap, anti-boucle, **ne lève jamais**. L'application saute les
/// lignes locales `PENDING_SYNC` (jamais de clobber d'écriture non
/// synchronisée).
///
/// **`403` = garde d'ownership serveur (DF-L point 2)** : le cours a été
/// réaffecté à un autre prof entre le pull `cours` (qui l'a laissé en local) et
/// ce pull métier. Non fatal : le cours est évincé localement (référence +
/// évaluations/notes) et le cycle continue sur les cours suivants — distinct du
/// `400` (curseur à rebootstrapper) et des erreurs réseau/5xx (retry).
class AcademicsMetierPullRepositoryImpl {
  final AcademicsMetierPullApi _api;
  final AcademicsLocalDataSource _local;
  final AcademicsRefLocalDataSource _refLocal;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final CurrentUserContext? _currentUser;
  final Clock _now;

  static const int pageLimit = 100;

  AcademicsMetierPullRepositoryImpl({
    required AcademicsMetierPullApi api,
    required AcademicsLocalDataSource localDataSource,
    required AcademicsRefLocalDataSource refLocalDataSource,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    CurrentUserContext? currentUser,
    Clock now = systemClock,
  }) : _api = api,
       _local = localDataSource,
       _refLocal = refLocalDataSource,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _currentUser = currentUser,
       _now = now;

  Future<Either<Failure, AcademicsDeltaPullOutcome>>? _evaluationsTail;
  Future<Either<Failure, AcademicsDeltaPullOutcome>>? _notesTail;

  /// Pull des évaluations de tous les cours locaux.
  Future<Either<Failure, AcademicsDeltaPullOutcome>> syncEvaluations() {
    late final Future<Either<Failure, AcademicsDeltaPullOutcome>> scheduled;
    final prev = _evaluationsTail;
    Future<Either<Failure, AcademicsDeltaPullOutcome>> run() =>
        _pullAllCours<EvaluationDeltaDto>(
          resourcePrefix: kAcademicsEvaluationsResourcePrefix,
          fetchPage: (coursId, cursor) async => (await _api.pullEvaluations(
            _requiredAuth,
            coursId,
            cursor,
            pageLimit,
          )).data,
          apply: (page, syncedAt) => _local.applyPulledEvaluations(
            page.items.map((d) => d.toLocalRow(syncedAt)).toList(),
          ),
        );
    final future = prev == null ? run() : prev.then((_) => run());
    scheduled = future.whenComplete(() {
      if (identical(_evaluationsTail, scheduled)) _evaluationsTail = null;
    });
    _evaluationsTail = scheduled;
    return scheduled;
  }

  /// Pull des notes de tous les cours locaux.
  Future<Either<Failure, AcademicsDeltaPullOutcome>> syncNotes() {
    late final Future<Either<Failure, AcademicsDeltaPullOutcome>> scheduled;
    final prev = _notesTail;
    Future<Either<Failure, AcademicsDeltaPullOutcome>> run() =>
        _pullAllCours<NoteDeltaDto>(
          resourcePrefix: kAcademicsNotesResourcePrefix,
          fetchPage: (coursId, cursor) async => (await _api.pullNotes(
            _requiredAuth,
            coursId,
            cursor,
            pageLimit,
          )).data,
          apply: (page, syncedAt) => _local.applyPulledNotes(
            page.items.map((d) => d.toLocalRow(syncedAt)).toList(),
          ),
        );
    final future = prev == null ? run() : prev.then((_) => run());
    scheduled = future.whenComplete(() {
      if (identical(_notesTail, scheduled)) _notesTail = null;
    });
    _notesTail = scheduled;
    return scheduled;
  }

  Future<Either<Failure, AcademicsDeltaPullOutcome>> _pullAllCours<I>({
    required String resourcePrefix,
    required Future<KeysetPageDto<I>> Function(String coursId, String? cursor)
    fetchPage,
    required Future<int> Function(KeysetPageDto<I> page, int syncedAt) apply,
  }) async {
    final syncedAt = _now();
    final List<String> coursIds;
    try {
      // Itération bornée aux cours du compte connecté : ceux d'un collègue
      // présent sur la même tablette ne sont pas les nôtres à tirer (403 en
      // boucle au mieux, contenu d'autrui rapatrié au pire).
      coursIds = (await _refLocal.getAllCours(
        ownerUid: _currentUser?.uid,
      )).map((c) => c.id).toList(growable: false);
    } catch (_) {
      return const Left(ServerFailure('Lecture des cours locaux échouée'));
    }

    if (coursIds.isEmpty) {
      return Right(
        AcademicsDeltaPullOutcome(
          upserted: 0,
          notModified: true,
          bootstrapComplete: false,
          syncedAt: syncedAt,
        ),
      );
    }

    // Best-effort : un cours en échec est SAUTÉ (les autres continuent) — sinon
    // un cours cassé gèlerait la synchro des évaluations/notes de tous les cours
    // suivants. `Left` seulement si TOUS échouent.
    var totalUpserted = 0;
    var allNotModified = true;
    var allBootstrapComplete = true;
    var anySucceeded = false;
    int? latestServerTimeMs;
    Failure? lastFailure;
    for (final coursId in coursIds) {
      final cycle = await _pullCours<I>(
        resourcePrefix,
        coursId,
        syncedAt,
        fetchPage,
        apply,
      );
      Failure? failure;
      _CourseCycle? applied;
      cycle.fold((f) => failure = f, (c) => applied = c);
      if (failure != null) {
        lastFailure = failure;
        allBootstrapComplete = false;
        allNotModified = false;
        continue;
      }
      anySucceeded = true;
      totalUpserted += applied!.upserted;
      allNotModified = allNotModified && applied!.notModified;
      allBootstrapComplete = allBootstrapComplete && applied!.bootstrapComplete;
      final observed = applied!.serverTimeMs;
      if (observed != null &&
          (latestServerTimeMs == null || observed > latestServerTimeMs)) {
        latestServerTimeMs = observed;
      }
    }

    if (!anySucceeded && lastFailure != null) return Left(lastFailure);
    return Right(
      AcademicsDeltaPullOutcome(
        upserted: totalUpserted,
        notModified: allNotModified,
        bootstrapComplete: allBootstrapComplete,
        syncedAt: syncedAt,
        serverTimeMs: latestServerTimeMs,
      ),
    );
  }

  Future<Either<Failure, _CourseCycle>> _pullCours<I>(
    String resourcePrefix,
    String coursId,
    int syncedAt,
    Future<KeysetPageDto<I>> Function(String coursId, String? cursor) fetchPage,
    Future<int> Function(KeysetPageDto<I> page, int syncedAt) apply,
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
    required Future<KeysetPageDto<I>> Function(String coursId, String? cursor)
    fetchPage,
    required Future<int> Function(KeysetPageDto<I> page, int syncedAt) apply,
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
            _CourseCycle(
              upserted: 0,
              notModified: true,
              bootstrapComplete: await _isBootstrapComplete(bootstrapResource),
            ),
          ),
        );
      }
      if (status == 403) {
        // Cours perdu (réaffectation) : éviction non fatale, cycle réputé à
        // jour pour ce cours — les autres cours du batch continuent.
        await _refLocal.evictCours(coursId);
        await _local.evictCoursData(coursId);
        // Purge les curseurs des DEUX ressources (pas seulement celle qui a
        // 403), pas seulement la sienne : le cours disparaît de `ref_cours`
        // ici, donc l'autre pull (évaluations si on vient des notes, ou
        // l'inverse) ne le reverra plus jamais dans `getAllCours()` — son
        // curseur resterait orphelin et périmé sinon (une réaffectation en
        // retour reprendrait au lieu de rebootstraper → perte silencieuse).
        for (final prefix in const [
          kAcademicsEvaluationsResourcePrefix,
          kAcademicsNotesResourcePrefix,
        ]) {
          await _syncMetaDao.deleteCursor('$prefix:$coursId');
          await _syncMetaDao.deleteCursor('${prefix}_bootstrap:$coursId');
        }
        return const _CycleAttempt(
          Right(
            _CourseCycle(
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

  Future<_CourseCycle> _runCycle<I>(
    String resourcePrefix,
    String coursId,
    int syncedAt, {
    required String? from,
    required Future<KeysetPageDto<I>> Function(String coursId, String? cursor)
    fetchPage,
    required Future<int> Function(KeysetPageDto<I> page, int syncedAt) apply,
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
    return _CourseCycle(
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
