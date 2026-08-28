import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';

/// Lit l'enveloppe d'erreur du serveur (`ApiErrorResponse`) et la traduit en
/// [Failure] typée.
///
/// **Parsing tolérant, par principe.** Le corps d'une réponse d'erreur est ce
/// qu'on maîtrise le moins : un proxy peut rendre du HTML, une passerelle une
/// chaîne nue, et le catalogue de codes du serveur grandit sans release client.
/// Rien ici ne lève : tout ce qui n'est pas reconnu dégrade vers le
/// comportement générique du statut HTTP, qui reste correct.
///
/// Se brancher sur `code`, **jamais sur `message`** — celui-ci est rédigé pour
/// un humain et change sans préavis.
class ApiErrorParser {
  const ApiErrorParser._();

  /// Corps de la réponse sous forme de map, ou `null` si rien d'exploitable.
  ///
  /// Dio rend déjà une `Map` quand le `Content-Type` est JSON, mais pas toujours :
  /// une réponse d'erreur sur une route qui sert des octets (l'éditique) arrive
  /// en `String`, voire en `List<int>`. Les trois cas sont couverts.
  static Map<String, dynamic>? _bodyOf(Response<dynamic>? response) {
    final data = response?.data;
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();

    late final String raw;
    if (data is String) {
      raw = data;
    } else if (data is List<int>) {
      try {
        raw = utf8.decode(data, allowMalformed: true);
      } catch (_) {
        return null;
      }
    } else {
      return null;
    }

    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      // Corps non-JSON (page d'erreur d'un proxy) : le statut suffit.
    }
    return null;
  }

  /// Code typé porté par la réponse, ou [ApiErrorCode.unknown].
  static ApiErrorCode codeOf(Response<dynamic>? response) =>
      ApiErrorCode.fromWire(_bodyOf(response)?['code']);

  /// Message rédigé par le serveur, `null` s'il est absent ou vide.
  static String? serverMessageOf(Response<dynamic>? response) {
    final message = _bodyOf(response)?['message'];
    if (message is! String) return null;
    final trimmed = message.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Référence d'incident, posée par le serveur sur les seules pannes 5xx.
  static String? incidentIdOf(Response<dynamic>? response) {
    final incidentId = _bodyOf(response)?['incidentId'];
    if (incidentId is! String) return null;
    final trimmed = incidentId.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Délai annoncé par `Retry-After`, quand il est exprimé en secondes.
  ///
  /// La RFC autorise aussi une date HTTP ; on ne la lit pas — un compte à
  /// rebours faux serait pire que pas de compte à rebours du tout, et l'écran
  /// sait se passer du délai.
  static Duration? retryAfterOf(Response<dynamic>? response) {
    final raw = response?.headers.value('retry-after');
    if (raw == null) return null;
    final seconds = int.tryParse(raw.trim());
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
  }

  /// [ApiValidationFailure] pour un 400 ou un 422.
  static ApiValidationFailure validationFailure(Response<dynamic>? response) =>
      ApiValidationFailure(
        code: codeOf(response),
        serverMessage: serverMessageOf(response),
      );

  /// [ApiServerFailure] pour un 5xx, avec sa référence d'incident si elle existe.
  static ApiServerFailure serverFailure(Response<dynamic>? response) =>
      ApiServerFailure(
        code: codeOf(response),
        serverMessage: serverMessageOf(response),
        incidentId: incidentIdOf(response),
      );

  /// [TooManyRequestsFailure] pour un 429.
  static TooManyRequestsFailure tooManyRequestsFailure(
    Response<dynamic>? response,
  ) => TooManyRequestsFailure(
    retryAfter: retryAfterOf(response),
    serverMessage: serverMessageOf(response),
  );
}
