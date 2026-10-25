import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/boutique_dashboard_api.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/boutique_dashboard_cache_dao.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_beneficiaries_page_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_stats_model.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/beneficiary_offline_filter.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/stats_bucket_keys.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_snapshot.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_dashboard_repository.dart';

/// Les chiffres du tableau de bord : le serveur d'abord, la dernière photo
/// **datée** quand — et seulement quand — le réseau manque.
///
/// Un 401, un 403 ou un 500 ne se replient jamais sur le cache : un droit
/// retiré doit se voir retiré, et une panne serveur n'est pas une coupure.
class BoutiqueDashboardRepositoryImpl implements BoutiqueDashboardRepository {
  final BoutiqueDashboardApi _api;
  final BoutiqueDashboardCacheDao _cache;
  final CurrentUserContext _currentUser;
  final ConnectivityService _connectivity;
  final Map<String, dynamic> _requiredAuth;
  final DateTime Function() _now;

  const BoutiqueDashboardRepositoryImpl({
    required BoutiqueDashboardApi api,
    required BoutiqueDashboardCacheDao cache,
    required CurrentUserContext currentUser,
    required ConnectivityService connectivity,
    required Map<String, dynamic> requiredAuth,
    DateTime Function() now = DateTime.now,
  }) : _api = api,
       _cache = cache,
       _currentUser = currentUser,
       _connectivity = connectivity,
       _requiredAuth = requiredAuth,
       _now = now;

  @override
  Future<Either<Failure, BoutiqueStatsSnapshot>> stats({
    required String academicYearId,
    required DashboardWindow window,
  }) => _fetch(
    academicYearId: academicYearId,
    kind: BoutiqueDashboardCacheKind.stats,
    spanDays: window.dayCount,
    call: () async {
      final model = await _api.getStats(
        _requiredAuth,
        StatsBucketKeys.dayKey(window.from),
        StatsBucketKeys.dayKey(window.to),
        academicYearId,
      );
      return (model.toJson(), BoutiqueStatsSnapshot(stats: model.toEntity()));
    },
    // Les fenêtres sont calendaires : à largeur égale, « Cette semaine » un
    // mercredi et « Ce mois » le 3 sont deux fenêtres différentes. Seule la
    // photo de LA fenêtre demandée se sert.
    fromCache: (payload, at) {
      final requested = _windowOf(window);
      if (payload['from'] != requested['from'] ||
          payload['to'] != requested['to']) {
        return null;
      }
      return BoutiqueStatsSnapshot(
        stats: BoutiqueStatsModel.fromJson(payload).toEntity(),
        cachedAt: at,
      );
    },
  );

  @override
  Future<Either<Failure, BoutiqueBeneficiariesPage>> beneficiaries(
    BeneficiariesQuery query,
  ) => _fetch(
    academicYearId: query.academicYearId,
    kind: BoutiqueDashboardCacheKind.beneficiaries,
    spanDays: query.window.dayCount,
    // Seule la première page sans filtre se garde : c'est sur elle qu'une
    // recherche hors ligne se rejoue.
    cacheable: query.isUnfiltered && query.page == 0,
    call: () async {
      final model = await _api.getBeneficiaries(
        _requiredAuth,
        StatsBucketKeys.dayKey(query.window.from),
        StatsBucketKeys.dayKey(query.window.to),
        query.academicYearId,
        query.articleId,
        query.classId,
        _searchOf(query.search),
        query.page,
        query.size,
      );
      // La réponse de R9 ne dit pas sa fenêtre : la photo la porte, sans quoi
      // « aujourd'hui » montrerait hors ligne les élèves servis avant-hier.
      return (
        {..._windowOf(query.window), 'response': model.toJson()},
        model.toEntity(),
      );
    },
    fromCache: (payload, at) {
      final window = _windowOf(query.window);
      if (payload['from'] != window['from'] || payload['to'] != window['to']) {
        return null;
      }
      return BeneficiaryOfflineFilter.apply(
        BoutiqueBeneficiariesPageModel.fromJson(
          payload['response'] as Map<String, dynamic>,
        ).toEntity().cached(at),
        query,
      );
    },
  );

  static Map<String, String> _windowOf(DashboardWindow window) => {
    'from': StatsBucketKeys.dayKey(window.from),
    'to': StatsBucketKeys.dayKey(window.to),
  };

  /// Le chemin commun : réseau, photo en cas de succès, repli en cas de
  /// coupure.
  Future<Either<Failure, T>> _fetch<T>({
    required String academicYearId,
    required BoutiqueDashboardCacheKind kind,
    required int spanDays,
    required Future<(Map<String, dynamic>, T)> Function() call,
    required T? Function(Map<String, dynamic> payload, DateTime at) fromCache,
    bool cacheable = true,
  }) async {
    final schoolId = _currentUser.schoolId ?? '';

    Future<Either<Failure, T>> offline(Failure failure) async {
      final cached = await _readQuietly(
        schoolId: schoolId,
        academicYearId: academicYearId,
        kind: kind,
        spanDays: spanDays,
        fromCache: fromCache,
      );
      return cached == null ? Left(failure) : Right(cached);
    }

    // Pré-garde, pas verdict : la radio « up » ne prouve pas la joignabilité,
    // l'appel reste seul juge quand elle passe.
    if (!await _connectivity.isOnline()) {
      return offline(const NetworkFailure('Aucune connexion.'));
    }

    try {
      final (payload, value) = await call();
      if (cacheable) {
        await _writeQuietly(
          schoolId: schoolId,
          academicYearId: academicYearId,
          kind: kind,
          spanDays: spanDays,
          payload: payload,
        );
      }
      return Right(value);
    } on DioException catch (e) {
      if (e.error is Failure) {
        final failure = e.error as Failure;
        return failure is NetworkFailure ? offline(failure) : Left(failure);
      }
      // Sans réponse : une coupure, la photo a sa place. Avec une réponse que
      // l'intercepteur n'a pas classée (route renommée, 405, 410…), c'est une
      // erreur — une vieille photo la masquerait.
      return e.response == null
          ? offline(const NetworkFailure('Network error occurred'))
          : const Left(ServerFailure('Unexpected response'));
    } catch (_) {
      // `fromJson` lève sur une réponse sans fenêtre ni compteurs : mieux vaut
      // dire « erreur » que montrer un tableau de bord vide.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  Future<T?> _readQuietly<T>({
    required String schoolId,
    required String academicYearId,
    required BoutiqueDashboardCacheKind kind,
    required int spanDays,
    required T? Function(Map<String, dynamic> payload, DateTime at) fromCache,
  }) async {
    try {
      final cached = await _cache.read(
        schoolId: schoolId,
        academicYearId: academicYearId,
        kind: kind,
        spanDays: spanDays,
      );
      return cached == null
          ? null
          : fromCache(cached.payload, cached.fetchedAt);
    } catch (_) {
      // Une photo illisible ne vaut pas mieux que pas de photo : l'erreur
      // réseau, honnête, s'affiche à sa place.
      return null;
    }
  }

  /// Avalée : la réponse est en main, la perdre pour une écriture de cache qui
  /// a bronché serait absurde.
  Future<void> _writeQuietly({
    required String schoolId,
    required String academicYearId,
    required BoutiqueDashboardCacheKind kind,
    required int spanDays,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _cache.write(
        schoolId: schoolId,
        academicYearId: academicYearId,
        kind: kind,
        spanDays: spanDays,
        payload: payload,
        fetchedAt: _now(),
      );
    } catch (_) {}
  }

  static String? _searchOf(String? search) {
    final trimmed = search?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
