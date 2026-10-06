import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_keyset_cycle.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';

/// Le moteur des flux KEYSET **itérés par cours** (évaluations, notes,
/// chapitres) : les cours sont lus dans `ref_cours` (pull cours scopé
/// enseignant, DF-K), chacun avec un curseur propre par ressource — clé
/// `<préfixe>:<coursId>`. Résumable, 304, 400 ⇒ rebootstrap, anti-boucle,
/// **ne lève jamais**.
///
/// Best-effort : un cours en échec est sauté, les suivants continuent ; `Left`
/// seulement si tous échouent. Un 403 `COURS_NOT_OWNED` n'est pas un échec :
/// le cours est évincé ([CoursEviction]) et le cycle le compte à jour.
///
/// Deux tirages d'une même ressource se suivent, jamais ne se chevauchent.
class PerCoursKeysetPuller {
  final AcademicsRefLocalDataSource _refLocal;
  final CoursKeysetCycle _cycle;
  final CurrentUserContext? _currentUser;
  final Clock _now;

  PerCoursKeysetPuller({
    required AcademicsRefLocalDataSource refLocalDataSource,
    required SyncMetaDao syncMetaDao,
    required CoursEviction eviction,
    CurrentUserContext? currentUser,
    Clock now = systemClock,
  }) : _refLocal = refLocalDataSource,
       _cycle = CoursKeysetCycle(syncMetaDao: syncMetaDao, eviction: eviction),
       _currentUser = currentUser,
       _now = now;

  final Map<String, Future<Either<Failure, AcademicsDeltaPullOutcome>>> _tails =
      {};

  /// Tire la ressource [resourcePrefix] de tous les cours du compte.
  Future<Either<Failure, AcademicsDeltaPullOutcome>> pull<I>({
    required String resourcePrefix,
    required CoursPageFetcher<I> fetchPage,
    required CoursPageApplier<I> apply,
  }) {
    late final Future<Either<Failure, AcademicsDeltaPullOutcome>> scheduled;
    final prev = _tails[resourcePrefix];
    Future<Either<Failure, AcademicsDeltaPullOutcome>> run() =>
        _pullAllCours<I>(resourcePrefix, fetchPage, apply);
    final future = prev == null ? run() : prev.then((_) => run());
    scheduled = future.whenComplete(() {
      if (identical(_tails[resourcePrefix], scheduled)) {
        _tails.remove(resourcePrefix);
      }
    });
    _tails[resourcePrefix] = scheduled;
    return scheduled;
  }

  Future<Either<Failure, AcademicsDeltaPullOutcome>> _pullAllCours<I>(
    String resourcePrefix,
    CoursPageFetcher<I> fetchPage,
    CoursPageApplier<I> apply,
  ) async {
    final syncedAt = _now();
    final List<String> coursIds;
    try {
      // Itération bornée aux cours du compte connecté : ceux d'un collègue
      // présent sur la même tablette ne sont pas les nôtres à tirer.
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

    var totalUpserted = 0;
    var allNotModified = true;
    var allBootstrapComplete = true;
    var anySucceeded = false;
    int? latestServerTimeMs;
    Failure? lastFailure;
    for (final coursId in coursIds) {
      final cycle = await _cycle.run<I>(
        resourcePrefix,
        coursId,
        syncedAt,
        fetchPage,
        apply,
      );
      Failure? failure;
      CoursCycleResult? applied;
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
}
