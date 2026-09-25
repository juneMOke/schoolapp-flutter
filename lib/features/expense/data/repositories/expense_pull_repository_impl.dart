import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_pull_outcome.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_pull_repository.dart';

/// Clé `sync_meta` du curseur, **scopée par école** : sur une tablette
/// réaffectée, un curseur nu ferait reprendre la seconde école là où la
/// première s'était arrêtée, et son registre ne descendrait jamais.
String expensesCursorKey(String schoolId) => '$kExpensesResource@$schoolId';

/// Pull keyset du registre des dépenses.
///
/// Squelette de la boutique, sans année : le registre est cadré par l'école
/// et se parcourt sans borne vers le passé. Trois gardes reprises à
/// l'identique — reprise par page, repli au bootstrap sur un curseur rejeté
/// (400), refus de boucler sur un serveur qui n'avance pas.
class ExpensePullRepositoryImpl implements ExpensePullRepository {
  final ExpenseSyncApi _api;
  final ExpenseSyncDao _dao;
  final SyncMetaDao _syncMetaDao;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  const ExpensePullRepositoryImpl({
    required ExpenseSyncApi api,
    required ExpenseSyncDao dao,
    required SyncMetaDao syncMetaDao,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _syncMetaDao = syncMetaDao,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth,
       _now = now;

  /// Taille de page keyset.
  ///
  /// **50, et non le défaut serveur de 100** (Q9) : depuis le circuit, chaque
  /// demande descend avec son **fil entier** — la pagination porte sur les
  /// demandes, jamais sur les messages, donc jamais de fil tronqué en
  /// silence. Une page de 100 demandes bavardes pèserait le double sans rien
  /// apporter. Le défaut serveur est partagé par tous les flux : c'est au
  /// poste de demander plus court.
  static const int pageLimit = 50;

  @override
  Future<Either<Failure, ExpensePullOutcome>> syncExpenses() async {
    final syncedAt = _now();
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return const Left(ServerFailure('Aucune école courante'));
    }
    final resource = expensesCursorKey(schoolId);
    final stored = await _syncMetaDao.getCursor(resource);

    final first = await _attempt(resource, schoolId, syncedAt, from: stored);
    // 400 = jeton illisible, forgé ou émis pour une autre ressource : repartir
    // du bootstrap, sinon le jeton fautif serait rejoué à chaque cycle.
    if (first.rejectedCursor && stored != null) {
      await _syncMetaDao.setCursor(resource, cursor: null, syncedAt: syncedAt);
      return (await _attempt(resource, schoolId, syncedAt, from: null)).result;
    }
    return first.result;
  }

  Future<_Attempt> _attempt(
    String resource,
    String schoolId,
    int syncedAt, {
    required String? from,
  }) async {
    try {
      return _Attempt(Right(await _cycle(resource, schoolId, syncedAt, from)));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 304) {
        // Rien de neuf : jeton CONSERVÉ (relu, jamais `from` — un 304 en cours
        // de cycle rembobinerait derrière les pages appliquées).
        final kept = await _syncMetaDao.getCursor(resource);
        await _syncMetaDao.setCursor(
          resource,
          cursor: kept,
          syncedAt: syncedAt,
        );
        return _Attempt(
          Right(ExpensePullOutcome.notModifiedAt(syncedAt, kept)),
        );
      }
      return _Attempt(
        Left(ServerFailure(e.message ?? e.toString())),
        rejectedCursor: status == 400,
      );
    } on _IncoherentKeysetPage catch (_) {
      return const _Attempt(
        Left(ServerFailure('Page keyset incohérente : hasMore sans curseur')),
      );
    } catch (_) {
      return const _Attempt(
        Left(ServerFailure('Réponse de pull des dépenses illisible')),
      );
    }
  }

  Future<ExpensePullOutcome> _cycle(
    String resource,
    String schoolId,
    int syncedAt,
    String? from,
  ) async {
    var cursor = from;
    var upserted = 0;
    String? lastServerTime;

    while (true) {
      final sent = cursor;
      final HttpResponse<ExpensePageDto> response = await _api.pullExpenses(
        _requiredAuth,
        sent,
        pageLimit,
      );
      final page = response.data;
      lastServerTime = page.page.serverTime;
      upserted += await _dao.applyPulled(
        page.items,
        schoolId: schoolId,
        nowMs: syncedAt,
      );

      final next = page.page.cursorToPersist;
      if (next != null) cursor = next;
      await _syncMetaDao.setCursor(
        resource,
        cursor: cursor,
        syncedAt: syncedAt,
      );

      if (!page.page.hasMore) break;
      // Anti-boucle : `hasMore` sans curseur neuf = serveur défaillant. Lever
      // plutôt que sortir, sinon chaque cycle rejouerait la même page.
      if (page.page.nextCursor == null || page.page.nextCursor == sent) {
        throw const _IncoherentKeysetPage();
      }
    }

    return upserted == 0
        ? ExpensePullOutcome.notModifiedAt(syncedAt, cursor)
        : ExpensePullOutcome(
            upserted: upserted,
            notModified: false,
            syncedAt: syncedAt,
            cursor: cursor,
            serverTimeMs: EpochIsoHelper.tryToEpochMs(lastServerTime),
          );
  }
}

class _Attempt {
  final Either<Failure, ExpensePullOutcome> result;
  final bool rejectedCursor;

  const _Attempt(this.result, {this.rejectedCursor = false});
}

class _IncoherentKeysetPage implements Exception {
  const _IncoherentKeysetPage();
}
