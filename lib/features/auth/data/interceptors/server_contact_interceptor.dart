import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';

/// Intercepteur **observateur** (ADR-010 §7.3 / D-09) : sur chaque réponse
/// authentifiée (200 **et** 304), lit le header applicatif `X-User-Version` et
/// le header HTTP `Date` (= `serverTime`, §0.5 A4) et les transmet au
/// [AuthSessionManager].
///
/// **Ne wipe jamais** et **ne rejette jamais** (D-11 : observer, pas décideur —
/// la révocation est décidée après le flush par le guardian). Totalement
/// défensif : aucune exception ne remonte dans le pipeline Dio.
class ServerContactInterceptor extends Interceptor {
  final AuthSessionManager _sessionManager;

  ServerContactInterceptor(this._sessionManager);

  static const String userVersionHeader = 'X-User-Version';

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _capture(response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Un 304 (Not Modified) peut arriver ici selon `validateStatus` : le header
    // `X-User-Version` y voyage aussi (corps vide). On le capte sans altérer le flux.
    final headers = err.response?.headers;
    if (headers != null) _capture(headers);
    handler.next(err);
  }

  void _capture(Headers headers) {
    try {
      final versionStr = headers.value(userVersionHeader);
      final dateStr = headers.value('date');
      final version = versionStr != null ? int.tryParse(versionStr) : null;
      final serverTimeMs = dateStr != null ? _parseHttpDate(dateStr) : null;
      if (version == null && serverTimeMs == null) return;
      // Fire-and-forget : n'attend pas l'écriture DB, ne propage aucune erreur.
      unawaitedCatch(
        _sessionManager.recordServerContact(
          observedUserVersion: version,
          serverTimeMs: serverTimeMs,
        ),
      );
    } catch (_) {
      // Header illisible : on ignore, le prochain contact re-observera.
    }
  }

  static int? _parseHttpDate(String value) {
    try {
      return HttpDate.parse(value).millisecondsSinceEpoch;
    } catch (_) {
      return null;
    }
  }
}

/// Avale toute erreur d'un future non attendu (garde-fou pipeline Dio).
void unawaitedCatch(Future<void> future) {
  future.catchError((_) {});
}
