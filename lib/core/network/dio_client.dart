import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

Dio createDioClient() {
  return Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}
