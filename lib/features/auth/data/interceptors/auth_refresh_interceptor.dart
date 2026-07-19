import 'package:dio/dio.dart';
import 'package:school_app_flutter/features/auth/data/services/token_refresher.dart';

/// Intercepteur de **refresh transparent** (ADR-010 §7.2 / D-07).
///
/// Sur un 401 d'une requête authentifiée (`requiresAuth`), tente **un** refresh
/// (single-flight via [TokenRefresher]) puis **rejoue** la requête d'origine
/// avec le nouvel access token. Si le refresh échoue, laisse l'erreur suivre son
/// cours (l'intercepteur d'erreurs la mappera, et le refresher aura déjà signalé
/// la révocation).
///
/// Doit être ajouté **avant** l'intercepteur qui mappe/rejette le 401. Le rejeu
/// passe par un `Dio` **nu** (header posé manuellement) pour éviter toute
/// ré-entrance.
class AuthRefreshInterceptor extends Interceptor {
  final TokenRefresher _refresher;
  final Dio _retryDio;

  AuthRefreshInterceptor({
    required TokenRefresher refresher,
    required Dio retryDio,
  }) : _refresher = refresher,
       _retryDio = retryDio;

  static const String _retriedFlag = '__auth_retried__';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final requiresAuth = options.extra['requiresAuth'] == true;
    final alreadyRetried = options.extra[_retriedFlag] == true;

    if (err.response?.statusCode != 401 || !requiresAuth || alreadyRetried) {
      return handler.next(err);
    }

    final newToken = await _refresher.refresh();
    if (newToken == null) {
      // Refresh impossible : la session est perdue (le refresher a signalé la
      // révocation). On laisse l'erreur poursuivre.
      return handler.next(err);
    }

    try {
      final retried = await _retryDio.fetch<dynamic>(
        options
          ..headers['Authorization'] = 'Bearer $newToken'
          ..extra[_retriedFlag] = true,
      );
      return handler.resolve(retried);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (_) {
      return handler.next(err);
    }
  }
}
