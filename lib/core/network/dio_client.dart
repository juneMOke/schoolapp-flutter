import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/config/env_config.dart';

/// En-têtes qui disent au back quelle version de poste de bureau l'appelle
/// (`X-Client-Version`, `X-Client-Platform`). Posés une fois au démarrage par
/// [configureClientHeaders] ; vides hors d'un poste de bureau ou tant que la
/// version est inconnue. Le back les ignore puis les journalise (lot L4).
Map<String, String> _clientHeaders = const {};

void configureClientHeaders(Map<String, String> headers) {
  _clientHeaders = Map.unmodifiable(headers);
}

Dio createDioClient(EnvConfig envConfig) {
  return Dio(
    BaseOptions(
      baseUrl: envConfig.apiBaseUrl,
      // connect 6 s : borne l'attente quand le réseau est « up » mais sans
      // internet (routeur sans backhaul — cas terrain fréquent). Le repli
      // login offline (ADR-010) n'est tenté qu'APRÈS l'échec online : ce délai
      // est donc le temps d'attente max de l'agent avant la bascule. 6 s ne
      // borne que l'établissement TCP — une requête normale répond ensuite
      // sous receiveTimeout (12 s).
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 12),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ..._clientHeaders,
      },
    ),
  );
}
