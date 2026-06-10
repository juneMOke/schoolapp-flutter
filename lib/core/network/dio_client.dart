import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/config/env_config.dart';

Dio createDioClient(EnvConfig envConfig) {
  return Dio(
    BaseOptions(
      baseUrl: envConfig.apiBaseUrl,
      // 12 s : un backend injoignable échoue vite (ex. splash → ErrorView)
      // plutôt que de pendre. Suffisant pour des requêtes API normales.
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}
