import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_cours_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/cours_pull_outcome.dart';

/// Préfixes `sync_meta` du curseur et du drapeau bootstrap **par classe** : la
/// clé effective est `academics_cours:{classroomId}` (un curseur keyset propre à
/// chaque classe, le contrat back scopant les cours par `classroomId`).
const String kAcademicsCoursResourcePrefix = 'academics_cours';
const String kAcademicsCoursBootstrapPrefix = 'academics_cours_bootstrap';

String _coursResource(String classroomId) =>
    '$kAcademicsCoursResourcePrefix:$classroomId';
String _coursBootstrap(String classroomId) =>
    '$kAcademicsCoursBootstrapPrefix:$classroomId';

/// Page keyset incohérente : `hasMore` sans curseur qui progresse.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

/// Résultat d'un cycle keyset pour UNE classe.
class _ClassroomCycle {
  final int upserted;
  final bool notModified;
  final bool bootstrapComplete;
  const _ClassroomCycle({
    required this.upserted,
    required this.notModified,
    required this.bootstrapComplete,
  });
}

class _CycleAttempt {
  final Either<Failure, _ClassroomCycle> result;
  final bool rejectedCursor;
  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pull KEYSET des cours (référence read-only), **itéré par classe** (option B) :
/// on lit les classes de l'année dans `ref_classrooms` (peuplée par le module
/// Classe), puis on tire les cours de chaque classe avec un **curseur keyset
/// propre à la classe**. Résumable (jeton opaque mémorisé par page), 304, 400→
/// rebootstrap, anti-boucle. Money-grade : ne **lève jamais** (échec en `Left`).
///
/// Sur échec d'une classe, on interrompt le cycle et on renvoie l'échec : le
/// coordinateur re-tentera tout le pull cours au prochain cycle, les classes
/// déjà tirées repartant de leur curseur (304 bon marché — idempotent).
class AcademicsCoursPullRepositoryImpl {
  final AcademicsCoursPullApi _api;
  final AcademicsRefLocalDataSource _local;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  static const int pageLimit = 100;

  AcademicsCoursPullRepositoryImpl({
    required AcademicsCoursPullApi api,
    required AcademicsRefLocalDataSource localDataSource,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _local = localDataSource,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _now = now;

  Future<Either<Failure, CoursPullOutcome>>? _tail;

  /// Pull des cours de toutes les classes de [academicYearId].
  Future<Either<Failure, CoursPullOutcome>> syncCours({
    required String academicYearId,
  }) {
    final prev = _tail;
    late final Future<Either<Failure, CoursPullOutcome>> scheduled;
    final run = prev == null
        ? _pullAll(academicYearId)
        : prev.then((_) => _pullAll(academicYearId));
    scheduled = run.whenComplete(() {
      if (identical(_tail, scheduled)) _tail = null;
    });
    _tail = scheduled;
    return scheduled;
  }

  Future<Either<Failure, CoursPullOutcome>> _pullAll(
    String academicYearId,
  ) async {
    final syncedAt = _now();
    final List<String> classroomIds;
    try {
      classroomIds = await _local.getClassroomIdsForYear(academicYearId);
    } catch (_) {
      return const Left(ServerFailure('Lecture des classes locales échouée'));
    }

    // Aucune classe locale : no-op propre (le pull Classe n'a pas encore
    // peuplé `ref_classrooms`). Réputé « à jour » (rien à tirer).
    if (classroomIds.isEmpty) {
      return Right(
        CoursPullOutcome(
          upserted: 0,
          notModified: true,
          bootstrapComplete: false,
          syncedAt: syncedAt,
        ),
      );
    }

    // Best-effort : une classe en échec est SAUTÉE (rafraîchie au prochain
    // cycle), les autres continuent — sinon une classe cassée (500 persistant)
    // gèlerait indéfiniment la synchro de toutes les classes suivantes (les ids
    // triés rendraient la privation stable). `Left` seulement si TOUT échoue.
    var totalUpserted = 0;
    var allNotModified = true;
    var allBootstrapComplete = true;
    var anySucceeded = false;
    Failure? lastFailure;
    for (final classroomId in classroomIds) {
      final cycle = await _pullClassroom(classroomId, syncedAt);
      Failure? failure;
      _ClassroomCycle? applied;
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
    }

    if (!anySucceeded && lastFailure != null) return Left(lastFailure);
    return Right(
      CoursPullOutcome(
        upserted: totalUpserted,
        notModified: allNotModified,
        bootstrapComplete: allBootstrapComplete,
        syncedAt: syncedAt,
      ),
    );
  }

  /// Un cycle keyset complet pour une classe (avec repli bootstrap sur 400).
  Future<Either<Failure, _ClassroomCycle>> _pullClassroom(
    String classroomId,
    int syncedAt,
  ) async {
    final resource = _coursResource(classroomId);
    final stored = await _syncMetaDao.getCursor(resource);
    final first = await _attemptCycle(classroomId, syncedAt, from: stored);
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      return (await _attemptCycle(classroomId, syncedAt, from: null)).result;
    }
    return first.result;
  }

  Future<_CycleAttempt> _attemptCycle(
    String classroomId,
    int syncedAt, {
    required String? from,
  }) async {
    final resource = _coursResource(classroomId);
    final bootstrapResource = _coursBootstrap(classroomId);
    try {
      return _CycleAttempt(
        Right(await _runCycle(classroomId, syncedAt, from: from)),
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
            _ClassroomCycle(
              upserted: 0,
              notModified: true,
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
        Left(ServerFailure('Invalid cours pull payload')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  Future<_ClassroomCycle> _runCycle(
    String classroomId,
    int syncedAt, {
    required String? from,
  }) async {
    final resource = _coursResource(classroomId);
    final bootstrapResource = _coursBootstrap(classroomId);
    var cursor = from;
    var upserted = 0;
    var reachedEnd = false;
    while (true) {
      final sent = cursor;
      final page = (await _api.pullCours(
        _requiredAuth,
        classroomId,
        sent,
        pageLimit,
      )).data;
      upserted += await _local.applyPulledCours(
        page.items.map((d) => d.toLocalRow(syncedAt)).toList(),
      );

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
    return _ClassroomCycle(
      upserted: upserted,
      notModified: upserted == 0,
      bootstrapComplete: await _isBootstrapComplete(bootstrapResource),
    );
  }

  Future<bool> _isBootstrapComplete(String bootstrapResource) async =>
      (await _syncMetaDao.getCursor(bootstrapResource)) != null;
}
