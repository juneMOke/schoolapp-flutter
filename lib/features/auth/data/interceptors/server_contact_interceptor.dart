import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';

/// Intercepteur **observateur** (ADR-010 §7.3 / D-09) : sur chaque réponse
/// **authentifiée et réussie** (2xx **et** 304), lit le header applicatif
/// `X-User-Version` et le header HTTP `Date` (= `serverTime`, §0.5 A4) et les
/// transmet au [AuthSessionManager], avec l'uid sous lequel la requête est
/// partie ([authUidExtra], posé par l'interceptor d'auth).
///
/// Deux filtres issus de la revue adversariale (règle d'or D-08 : seul un
/// contact serveur **authentifié réussi** peut améliorer le mode) :
/// - une réponse d'erreur (401 de flush, 4xx/5xx quelconque) porte aussi un
///   header `Date` — la capter ré-ancrerait la fraîcheur sans contact valide ;
/// - une requête publique (login, OTP) ne prouve pas la validité de la session.
///
/// **Ne wipe jamais** et **ne rejette jamais** (D-11 : observer, pas décideur —
/// la révocation est décidée après le flush par le guardian). Totalement
/// défensif : aucune exception ne remonte dans le pipeline Dio.
class ServerContactInterceptor extends Interceptor {
  final AuthSessionManager _sessionManager;

  ServerContactInterceptor(this._sessionManager);

  static const String userVersionHeader = 'X-User-Version';

  /// Clé `RequestOptions.extra` : uid de la session dont le JWT a été attaché
  /// à la requête. Posée par l'interceptor d'auth (injection.dart) au moment où
  /// il écrit le header Authorization.
  static const String authUidExtra = 'authUid';

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final status = response.statusCode;
    final success =
        status != null && ((status >= 200 && status < 300) || status == 304);
    if (success) _capture(response.headers, response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Un 304 (Not Modified) peut arriver ici selon `validateStatus` : le header
    // `X-User-Version` y voyage aussi (corps vide). C'est le SEUL statut
    // d'erreur qui vaut contact réussi — un 401/403/5xx ne ré-ancre rien.
    final response = err.response;
    if (response != null && response.statusCode == 304) {
      _capture(response.headers, err.requestOptions);
    }
    handler.next(err);
  }

  void _capture(Headers headers, RequestOptions requestOptions) {
    try {
      // Requête non authentifiée (pas de JWT attaché) → pas un contact de
      // session : ni ancre, ni version.
      final uid = requestOptions.extra[authUidExtra];
      if (uid is! String || uid.isEmpty) return;

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
          observedUid: uid,
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
