import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_pull_dao.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_pull_models.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sync_api.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_pull_outcome.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_pull_repository.dart';

/// Nom de ressource du flux des ventes — identité du `PullHandler` devant le
/// coordinateur et le plan de synchro (`kSyncPlanAliases`).
const String kBoutiqueSalesResource = 'boutique_sales';

/// Clé `sync_meta` du curseur keyset des ventes, **scopée par école**.
///
/// Le séparateur `@` est la convention du dépôt. Le scope n'est pas décoratif :
/// le flux est cadré par l'école du jeton, et un curseur unique sur une tablette
/// réaffectée ferait reprendre le second établissement au point où le premier
/// s'était arrêté. Le serveur répondrait « rien de neuf », et **les ventes de la
/// nouvelle école ne descendraient jamais** — le défaut déjà constaté sur dix
/// flux de ce dépôt.
String boutiqueSalesCursorKey(String schoolId) =>
    '$kBoutiqueSalesResource@$schoolId';

/// Pull keyset des ventes boutique.
///
/// Squelette repris de la Facturation, y compris ses trois gardes : reprise par
/// page, repli au bootstrap sur un curseur rejeté (400), et refus de boucler sur
/// un serveur qui n'avance pas.
class BoutiquePullRepositoryImpl implements BoutiquePullRepository {
  final BoutiqueSyncApi _api;
  final BoutiqueSalePullDao _dao;
  final SyncMetaDao _syncMetaDao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  /// Résout l'année courante — le flux est cadré par elle (ADR-009), pour que
  /// le volume reste constant dans le temps.
  final Future<String?> Function() _currentAcademicYearId;

  const BoutiquePullRepositoryImpl({
    required BoutiqueSyncApi api,
    required BoutiqueSalePullDao dao,
    required SyncMetaDao syncMetaDao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
    required Future<String?> Function() currentAcademicYearId,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _syncMetaDao = syncMetaDao,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth,
       _currentAcademicYearId = currentAcademicYearId,
       _now = now;

  /// Taille de page keyset (défaut serveur = 100, borné [1, 500]).
  static const int pageLimit = 100;

  @override
  Future<Either<Failure, BoutiquePullOutcome>> syncSales() async {
    final syncedAt = _now();
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      // Sans école, le curseur ne peut pas être scopé — et un curseur nu est
      // exactement ce que ce flux évite.
      return const Left(ServerFailure('Aucune école courante'));
    }
    final academicYearId = await _currentAcademicYearId();
    if (academicYearId == null || academicYearId.isEmpty) {
      // Le serveur exige l'année : sans elle, l'appel partirait en 400 à chaque
      // cycle. Mieux vaut ne pas le tenter et le dire.
      return const Left(ServerFailure('Aucune année académique courante'));
    }

    final resource = boutiqueSalesCursorKey(schoolId);
    final stored = await _syncMetaDao.getCursor(resource); // null = bootstrap

    final first = await _attemptCycle(
      resource,
      academicYearId,
      syncedAt,
      from: stored,
    );
    // 400 = curseur illisible, forgé, ou émis pour une autre ressource. Le
    // contrat impose de repartir du bootstrap : sans ce repli, le jeton fautif
    // serait rejoué à chaque cycle et la tablette ne syncherait plus jamais, en
    // silence.
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      // Un 400 au bootstrap n'est plus imputable au jeton : on n'insiste pas.
      return (await _attemptCycle(
        resource,
        academicYearId,
        syncedAt,
        from: null,
      )).result;
    }
    return first.result;
  }

  Future<_CycleAttempt> _attemptCycle(
    String resource,
    String academicYearId,
    int syncedAt, {
    required String? from,
  }) async {
    try {
      return _CycleAttempt(
        Right(await _runCycle(resource, academicYearId, syncedAt, from: from)),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        // Rien de neuf : jeton CONSERVÉ, fraîcheur bumpée. On relit le jeton
        // mémorisé plutôt que de réécrire `from` — un 304 peut tomber en cours
        // de cycle, et réécrire le jeton de départ rembobinerait derrière les
        // pages déjà appliquées.
        final kept = await _syncMetaDao.getCursor(resource);
        await _syncMetaDao.setCursor(
          resource,
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _CycleAttempt(
          Right(BoutiquePullOutcome.notModifiedAt(syncedAt, kept)),
        );
      }
      return _CycleAttempt(
        Left(ServerFailure(e.message ?? e.toString())),
        rejectedCursor: status == 400,
      );
    } on _IncoherentKeysetPage catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Page keyset incohérente : hasMore sans curseur')),
      );
    } on FormatException catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Réponse de pull boutique illisible')),
      );
    } catch (_) {
      return const _CycleAttempt(
        Left(ServerFailure('Unexpected error occurred')),
      );
    }
  }

  /// Un cycle complet : parcourt les pages, applique chacune, et mémorise le
  /// jeton à **chaque** page — un poste interrompu redémarre là où il en était.
  Future<BoutiquePullOutcome> _runCycle(
    String resource,
    String academicYearId,
    int syncedAt, {
    required String? from,
  }) async {
    var cursor = from;
    var upserted = 0;
    String? lastServerTime;

    while (true) {
      final sent = cursor;
      final HttpResponse<BoutiqueSalePageDto> response = await _api.pullSales(
        _requiredAuth,
        sent,
        pageLimit,
        academicYearId,
      );
      final page = response.data;
      lastServerTime = page.page.serverTime;
      upserted += await _dao.applySales(
        page.items,
        schoolId: _currentUser.schoolId ?? '',
        nowMs: syncedAt,
      );

      final nextToken = page.page.cursorToPersist;
      if (nextToken != null) cursor = nextToken;
      await _syncMetaDao.setCursor(
        resource,
        cursor: cursor,
        syncedAt: syncedAt,
      );

      if (!page.page.hasMore) break;
      // Anti-boucle : le keyset est strictement croissant. `hasMore` avec un
      // curseur absent ou identique = serveur défaillant. On LÈVE plutôt que de
      // sortir en silence — sortir rendrait un « updated » sur un curseur qui
      // ne bouge pas, et chaque cycle rejouerait la même page. Une tablette
      // bloquée pour toujours, comptée comme synchronisée.
      if (page.page.nextCursor == null || page.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    return upserted == 0
        ? BoutiquePullOutcome.notModifiedAt(syncedAt, cursor)
        : BoutiquePullOutcome(
            upserted: upserted,
            notModified: false,
            syncedAt: syncedAt,
            cursor: cursor,
            serverTimeMs: EpochIsoHelper.tryToEpochMs(lastServerTime),
          );
  }
}

class _CycleAttempt {
  final Either<Failure, BoutiquePullOutcome> result;

  /// Le seul cas rattrapable : le jeton envoyé a été rejeté, un bootstrap peut
  /// le dissoudre.
  final bool rejectedCursor;

  const _CycleAttempt(this.result, {this.rejectedCursor = false});
}

class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}
