import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/owner_scope.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_cours_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart'
    show kAcademicsEvaluationsResourcePrefix, kAcademicsNotesResourcePrefix;
import 'package:school_app_flutter/features/academics/domain/entities/offline/cours_pull_outcome.dart';

/// Clé `sync_meta` du curseur et du drapeau bootstrap de la ressource cours —
/// **une seule** ressource depuis DF-K (plus de clé par classe : le pull est
/// scopé enseignant côté serveur, un seul flux ramène tous les cours du prof).
const String kAcademicsCoursResourcePrefix = 'academics_cours';
const String kAcademicsCoursBootstrapPrefix = 'academics_cours_bootstrap';

/// Page keyset incohérente : `hasMore` sans curseur qui progresse.
class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}

class _CycleAttempt {
  final Either<Failure, CoursPullOutcome> result;
  final bool rejectedCursor;
  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

/// Pull KEYSET des cours du prof connecté (référence read-only), **ressource
/// unique** depuis le contrat back `1ec6be3` (DF-K) : plus d'itération par
/// classe, un seul curseur `sync_meta`. Résumable (jeton opaque mémorisé par
/// page), 304, 400→rebootstrap, anti-boucle. `404` = compte non lié à un
/// enseignant → traité comme un cycle à jour, jamais une erreur (« ne pas
/// boucler », spec front §5). Money-grade : ne **lève jamais**.
///
/// **Réconciliation DF-L** : le pull étant un delta additif, seul un cycle
/// **bootstrap complet** (curseur de départ `null`, càd un premier passage ou
/// un rejeu après 400) restitue l'ensemble courant des cours du prof — c'est
/// le SEUL moment où on peut savoir qu'un cours local est absent parce qu'il a
/// été réaffecté (le delta d'un cycle repris ne contient que des nouveautés,
/// jamais l'univers complet ; en diffuser l'absence évincerait à tort tout ce
/// qui n'a pas bougé depuis le dernier cycle). Sur un tel cycle, les cours
/// locaux absents de l'ensemble pullé sont évincés en cascade (référence +
/// squelette de notation + évaluations/notes).
class AcademicsCoursPullRepositoryImpl {
  final AcademicsCoursPullApi _api;
  final AcademicsRefLocalDataSource _refLocal;
  final AcademicsLocalDataSource _academicsLocal;
  final SyncMetaDao _syncMetaDao;
  final Map<String, dynamic> _requiredAuth;
  final CurrentUserContext? _currentUser;
  final Clock _now;

  static const int pageLimit = 100;

  AcademicsCoursPullRepositoryImpl({
    required AcademicsCoursPullApi api,
    required AcademicsRefLocalDataSource localDataSource,
    required AcademicsLocalDataSource academicsLocalDataSource,
    required SyncMetaDao syncMetaDao,
    required Map<String, dynamic> requiredAuth,
    CurrentUserContext? currentUser,
    Clock now = systemClock,
  }) : _api = api,
       _refLocal = localDataSource,
       _academicsLocal = academicsLocalDataSource,
       _syncMetaDao = syncMetaDao,
       _requiredAuth = requiredAuth,
       _currentUser = currentUser,
       _now = now;

  /// Compte au nom duquel le cycle tire, figé au début de `_pull` et transporté
  /// jusqu'à l'écriture et à l'éviction DF-L (cf. `owner_scope.dart`).
  String? get _ownerUid => _currentUser?.uid;

  String _resource(String? owner) =>
      scopedResource(kAcademicsCoursResourcePrefix, owner);

  String _bootstrapResource(String? owner) =>
      scopedResource(kAcademicsCoursBootstrapPrefix, owner);

  Future<Either<Failure, CoursPullOutcome>>? _tail;

  /// Pull des cours du prof connecté (scope token, DF-K).
  Future<Either<Failure, CoursPullOutcome>> syncCours() {
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
    final owner = _ownerUid;
    final stored = await _syncMetaDao.getCursor(_resource(owner));
    final first = await _attemptCycle(syncedAt, from: stored, owner: owner);
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(
        _resource(owner),
        cursor: null,
        syncedAt: syncedAt,
      );
      return (await _attemptCycle(syncedAt, from: null, owner: owner)).result;
    }
    return first.result;
  }

  Future<_CycleAttempt> _attemptCycle(
    int syncedAt, {
    required String? from,
    required String? owner,
  }) async {
    try {
      return _CycleAttempt(
        Right(await _runCycle(syncedAt, from: from, owner: owner)),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304 || status == 404) {
        // 304 = cycle sans changement ; 404 = compte non lié à un enseignant
        // (spec §5 : traiter comme « offline notation indisponible pour ce
        // compte », jamais une erreur qui boucle).
        final kept = await _syncMetaDao.getCursor(_resource(owner));
        await _syncMetaDao.setCursor(
          _resource(owner),
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _CycleAttempt(
          Right(
            CoursPullOutcome(
              upserted: 0,
              notModified: true,
              bootstrapComplete: await _isBootstrapComplete(owner),
              syncedAt: syncedAt,
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

  Future<CoursPullOutcome> _runCycle(
    int syncedAt, {
    required String? from,
    required String? owner,
  }) async {
    final bootstrapSweep = from == null;
    var cursor = from;
    var upserted = 0;
    var reachedEnd = false;
    String? lastServerTime;
    final seenIds = <String>{};
    while (true) {
      final sent = cursor;
      final page = (await _api.pullCours(_requiredAuth, sent, pageLimit)).data;
      lastServerTime = page.page.serverTime;
      for (final item in page.items) {
        seenIds.add(item.id);
      }
      upserted += await _refLocal.applyPulledCours(
        page.items.map((d) => d.toLocalRow(syncedAt)).toList(),
        ownerUid: owner,
      );

      final nextToken = page.page.cursorToPersist;
      if (nextToken != null) cursor = nextToken;
      await _syncMetaDao.setCursor(
        _resource(owner),
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
        _bootstrapResource(owner),
        cursor: 'DONE',
        syncedAt: syncedAt,
      );
      // DF-L : seul un cycle bootstrap complet restitue l'ensemble courant —
      // un cycle repris (delta) ne porte que des nouveautés, y diffuser une
      // éviction évincerait à tort tout ce qui n'a pas changé depuis.
      if (bootstrapSweep) {
        // Éviction bornée au compte courant : le snapshot ne décrit que LUI.
        final stale = await _refLocal.evictCoursNotIn(seenIds, ownerUid: owner);
        for (final coursId in stale) {
          await _academicsLocal.evictCoursData(coursId);
          // Purge les curseurs évaluations/notes de ce cours — sinon une
          // réaffectation en retour reprendrait un curseur périmé au lieu de
          // rebootstraper, et perdrait silencieusement tout ce qui existait
          // avant l'éviction (même raison que le chemin 403, cf.
          // AcademicsMetierPullRepositoryImpl).
          for (final prefix in const [
            kAcademicsEvaluationsResourcePrefix,
            kAcademicsNotesResourcePrefix,
          ]) {
            await _syncMetaDao.deleteCursor('$prefix:$coursId');
            await _syncMetaDao.deleteCursor('${prefix}_bootstrap:$coursId');
          }
        }
      }
    }
    return CoursPullOutcome(
      upserted: upserted,
      notModified: upserted == 0,
      bootstrapComplete: await _isBootstrapComplete(owner),
      syncedAt: syncedAt,
      serverTimeMs: upserted == 0
          ? null
          : EpochIsoHelper.tryToEpochMs(lastServerTime),
    );
  }

  Future<bool> _isBootstrapComplete(String? owner) async =>
      (await _syncMetaDao.getCursor(_bootstrapResource(owner))) != null;
}
