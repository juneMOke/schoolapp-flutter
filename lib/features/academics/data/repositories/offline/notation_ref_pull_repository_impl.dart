import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academics/data/datasources/course_remote_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_notation_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/cours_pull_outcome.dart';

/// Clé de ressource du pull des squelettes de notation.
const String kNotationSkeletonResource = 'academics_cours_notation';

/// Pull du **squelette de notation par cours** (réf du détail cours) : arbre
/// période/sous-période + statut + effectif, requis hors ligne au détail cours
/// et à la garde de création (période clôturée).
///
/// Source = l'endpoint **online** `getCoursNotationDetail` (réutilisé
/// directement, PAS l'interface `CourseRepository` — celle-ci est rebindée
/// offline en NF-7b, l'utiliser bouclerait). Best-effort : itère les cours de
/// `ref_cours`, met chaque squelette en cache ; un cours en échec (réseau/parse)
/// est **sauté** (rafraîchi au prochain cycle), jamais fatal. Ne lève jamais.
class NotationRefPullRepositoryImpl {
  final CourseRemoteDataSource _remote;
  final AcademicsRefLocalDataSource _refLocal;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  NotationRefPullRepositoryImpl({
    required CourseRemoteDataSource remoteDataSource,
    required AcademicsRefLocalDataSource refLocalDataSource,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _remote = remoteDataSource,
       _refLocal = refLocalDataSource,
       _requiredAuth = requiredAuth,
       _now = now;

  Future<Either<Failure, CoursPullOutcome>>? _tail;

  /// Rafraîchit le squelette de notation de tous les cours locaux.
  Future<Either<Failure, CoursPullOutcome>> syncNotationSkeletons() {
    final prev = _tail;
    late final Future<Either<Failure, CoursPullOutcome>> scheduled;
    final run = prev == null ? _pull() : prev.then((_) => _pull());
    scheduled = run.whenComplete(() {
      if (identical(_tail, scheduled)) _tail = null;
    });
    _tail = scheduled;
    return scheduled;
  }

  Future<Either<Failure, CoursPullOutcome>> _pull() async {
    final syncedAt = _now();
    final List<String> coursIds;
    try {
      coursIds = (await _refLocal.getAllCours())
          .map((c) => c.id)
          .toList(growable: false);
    } catch (_) {
      return const Left(ServerFailure('Lecture des cours locaux échouée'));
    }
    if (coursIds.isEmpty) {
      return Right(
        CoursPullOutcome(
          upserted: 0,
          notModified: true,
          bootstrapComplete: false,
          syncedAt: syncedAt,
        ),
      );
    }

    var upserted = 0;
    var anyFailed = false;
    for (final coursId in coursIds) {
      try {
        final model = await _remote.getCoursNotationDetail(
          _requiredAuth,
          coursId,
        );
        await _refLocal.upsertCoursNotation(
          RefCoursNotationRow.fromDetail(model.toEntity(), syncedAt: syncedAt),
        );
        upserted++;
      } catch (_) {
        // Cours en échec (réseau/parse) : sauté, rafraîchi au prochain cycle.
        anyFailed = true;
      }
    }

    // Aucun cours rafraîchi ET au moins un échec (typiquement hors-ligne
    // transitoire) → erreur non-fatale, le coordinateur re-tentera.
    if (upserted == 0 && anyFailed) {
      return const Left(ServerFailure('Squelettes de notation indisponibles'));
    }
    return Right(
      CoursPullOutcome(
        upserted: upserted,
        notModified: upserted == 0,
        bootstrapComplete: !anyFailed,
        syncedAt: syncedAt,
      ),
    );
  }
}
