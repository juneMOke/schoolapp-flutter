import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/config/env_config.dart';

Dio createDioClient(EnvConfig envConfig) {
  return Dio(
    BaseOptions(
      baseUrl: envConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}
