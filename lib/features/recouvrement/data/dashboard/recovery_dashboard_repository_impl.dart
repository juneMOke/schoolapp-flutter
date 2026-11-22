import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/online_guard.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_api.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_cache_dao.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_wire.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';

/// Le serveur d'abord ; la dernière photo **datée**, quand — et seulement
/// quand — le réseau manque **et** que la photo répond à la même question.
///
/// Un 401, un 403, un 400 ou un 500 ne se replient jamais sur le cache : un
/// droit retiré doit se voir retiré, et une panne serveur n'est pas une
/// coupure.
class RecoveryDashboardRepositoryImpl implements RecoveryDashboardRepository {
  final RecoveryDashboardApi _api;
  final RecoveryDashboardCacheDao _cache;
  final CurrentUserContext _currentUser;
  final ConnectivityService _connectivity;
  final DateTime Function() _now;

  /// La dernière demande de chaque sorte : une réponse plus ancienne arrivée
  /// après elle ne remplace pas la photo — la photo est celle des DERNIERS
  /// réglages (arbitrage du 2026-11-22).
  final Map<RecoveryCacheKind, String> _latest = {};

  RecoveryDashboardRepositoryImpl({
    required RecoveryDashboardApi api,
    required RecoveryDashboardCacheDao cache,
    required CurrentUserContext currentUser,
    required ConnectivityService connectivity,
    DateTime Function() now = DateTime.now,
  }) : _api = api,
       _cache = cache,
       _currentUser = currentUser,
       _connectivity = connectivity,
       _now = now;

  @override
  Future<Either<Failure, RecoveryDashboard>> dashboard(
    String academicYearId,
    RecoveryQuestion question, {
    int pendingWrites = 0,
  }) => _fetch(
    academicYearId: academicYearId,
    kind: RecoveryCacheKind.dashboard,
    key: {'question': question.toJson()},
    cacheable: true,
    call: () => _api.dashboard({
      ...question.toQueryParameters(),
      'pendingWrites': pendingWrites,
    }),
    decode: RecoveryDashboardWire.dashboardFromJson,
    cached: (value, at) => value.cached(at),
  );

  @override
  Future<Either<Failure, RecoveryStudentsPage>> students(
    String academicYearId,
    RecoveryStudentsQuery query, {
    int pendingWrites = 0,
  }) => _fetch(
    academicYearId: academicYearId,
    kind: RecoveryCacheKind.students,
    key: {'question': query.question.toJson(), 'tab': query.tab.wire},
    cacheable: query.isCacheable,
    call: () => _api.students({
      ...query.toQueryParameters(),
      'pendingWrites': pendingWrites,
    }),
    decode: RecoveryDashboardWire.studentsFromJson,
    cached: (value, at) => value.cached(at),
  );

  @override
  Future<Either<Failure, RecoveryExportFile>> export(
    RecoveryStudentsQuery query,
    RecoveryExportFormat format, {
    int pendingWrites = 0,
  }) => guardOnline(
    () => _api.export({
      ...query.toExportParameters(),
      'pendingWrites': pendingWrites,
    }, format),
  );

  @override
  Future<RecoveryQuestion?> lastCachedQuestion(String academicYearId) async {
    try {
      final cached = await _cache.read(
        schoolId: _currentUser.schoolId ?? '',
        academicYearId: academicYearId,
        kind: RecoveryCacheKind.dashboard,
      );
      return RecoveryQuestion.fromJson(cached?.payload['question']);
    } catch (_) {
      return null;
    }
  }

  /// Le chemin commun : réseau, photo en cas de succès, repli en cas de
  /// coupure — sur la photo de la même question seulement.
  Future<Either<Failure, T>> _fetch<T>({
    required String academicYearId,
    required RecoveryCacheKind kind,
    required Map<String, dynamic> key,
    required bool cacheable,
    required Future<Map<String, dynamic>> Function() call,
    required T Function(Object? json) decode,
    required T Function(T value, DateTime at) cached,
  }) async {
    final schoolId = _currentUser.schoolId ?? '';
    final ticket = jsonEncode(key);
    if (cacheable) _latest[kind] = ticket;

    Future<Either<Failure, T>> offline(Failure failure) async {
      if (!cacheable) return Left(failure);
      try {
        final photo = await _cache.read(
          schoolId: schoolId,
          academicYearId: academicYearId,
          kind: kind,
        );
        if (photo == null || !_sameKey(photo.payload, key)) {
          return Left(failure);
        }
        return Right(
          cached(decode(photo.payload['response']), photo.fetchedAt),
        );
      } catch (_) {
        // Une photo illisible ne vaut pas mieux que pas de photo.
        return Left(failure);
      }
    }

    // Pré-garde, pas verdict : la radio « up » ne prouve pas la joignabilité.
    if (!await _connectivity.isOnline()) {
      return offline(const NetworkFailure('Aucune connexion.'));
    }

    final Map<String, dynamic> json;
    final T value;
    try {
      json = await call();
      value = decode(json);
    } on DioException catch (e) {
      if (e.error is NetworkFailure) return offline(e.error as NetworkFailure);
      if (e.error is Failure) return Left(e.error as Failure);
      // Sans réponse : une coupure. Avec une réponse que l'intercepteur n'a
      // pas classée, c'est une erreur — une vieille photo la masquerait.
      if (e.response == null) {
        return offline(const NetworkFailure('Network error occurred'));
      }
      return guardOnline<T>(() => Future.error(e));
    } catch (_) {
      // Réponse illisible : « erreur » plutôt qu'un tableau de bord à zéro.
      return const Left(ServerFailure('Réponse du recouvrement illisible.'));
    }

    if (cacheable && _latest[kind] == ticket) {
      try {
        await _cache.write(
          schoolId: schoolId,
          academicYearId: academicYearId,
          kind: kind,
          payload: {...key, 'response': json},
          fetchedAt: _now(),
        );
      } catch (_) {
        // La réponse est en main : une écriture de cache qui bronche ne la
        // fait pas perdre.
      }
    }
    return Right(value);
  }

  static bool _sameKey(Map<String, dynamic> payload, Map<String, dynamic> key) {
    for (final entry in key.entries) {
      if (entry.key == 'question') {
        final cached = RecoveryQuestion.fromJson(payload['question']);
        final wanted = RecoveryQuestion.fromJson(entry.value);
        if (cached == null || cached != wanted) return false;
      } else if (payload[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
