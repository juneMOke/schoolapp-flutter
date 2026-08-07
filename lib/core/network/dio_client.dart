import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/config/env_config.dart';

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
      },
    ),
  );
}
