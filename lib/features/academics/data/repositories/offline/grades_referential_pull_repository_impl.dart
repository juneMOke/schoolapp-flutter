import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/grades_referential_pull_api.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/cours_pull_outcome.dart';

/// Clé `sync_meta` du bundle `grades-referential`. Le champ `cursor` de
/// [SyncMetaDao] porte ici l'**ETag applicatif** (jeton opaque, jamais décodé),
/// pas un curseur keyset — même colonne, réutilisée pour ce que le contrat lui
/// donne (base64url d'un hash serveur).
const String kGradesReferentialResource = 'academics_grades_referential';

/// Pull du **bundle** `grades-referential` (ETag, cadré prof, NON paginé). Un
/// seul appel remplace intégralement les 5 tables réf — devient la SEULE
/// source du statut de clôture, des plafonds de saisie et des chapitres.
/// Money-grade : ne lève jamais.
class GradesReferentialPullRepositoryImpl {
  final GradesReferentialPullApi _api;
  final AcademicsRefLocalDataSource _refLocal;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  GradesReferentialPullRepositoryImpl({
    required GradesReferentialPullApi api,
    required AcademicsRefLocalDataSource refLocalDataSource,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _refLocal = refLocalDataSource,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _now = now;

  Future<Either<Failure, CoursPullOutcome>>? _tail;

  /// Rafraîchit le bundle de référentiel de saisie.
  Future<Either<Failure, CoursPullOutcome>> syncGradesReferential() {
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
    final storedEtag = await _syncMetaDao.getCursor(kGradesReferentialResource);
    try {
      final response = await _api.pullGradesReferential(
        _requiredAuth,
        storedEtag,
      );
      final bundle = response.data;
      await _refLocal.replaceGradesReferential(bundle);
      final newEtag = response.response.headers.value('etag') ?? storedEtag;
      await _syncMetaDao.setCursor(
        kGradesReferentialResource,
        cursor: newEtag,
        syncedAt: syncedAt,
      );
      final upserted =
          bundle.branches.length +
          bundle.ligneBaremes.length +
          bundle.chapitres.length +
          bundle.periodes.length +
          bundle.sousPeriodes.length;
      return Right(
        CoursPullOutcome(
          upserted: upserted,
          notModified: false,
          bootstrapComplete: true,
          syncedAt: syncedAt,
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        // Bundle inchangé : cache local conservé, seule la fraîcheur avance.
        await _syncMetaDao.setCursor(
          kGradesReferentialResource,
          cursor: storedEtag,
          syncedAt: syncedAt,
        );
        return Right(
          CoursPullOutcome(
            upserted: 0,
            notModified: true,
            bootstrapComplete: true,
            syncedAt: syncedAt,
          ),
        );
      }
      if (status == 404) {
        // Compte non lié à un enseignant : « référentiel indisponible pour ce
        // compte », jamais une erreur qui boucle (même traitement que les
        // autres pulls académiques cadrés prof).
        return Right(
          CoursPullOutcome(
            upserted: 0,
            notModified: true,
            bootstrapComplete: false,
            syncedAt: syncedAt,
          ),
        );
      }
      return Left(ServerFailure(e.message ?? e.toString()));
    } on FormatException catch (_) {
      return const Left(ServerFailure('Invalid grades-referential payload'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
