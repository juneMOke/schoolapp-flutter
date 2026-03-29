import 'package:school_app_flutter/features/auth/data/models/api_error_detail_model.dart';

class ApiErrorResponseModel {
  final int? status;
  final String? message;
  final List<ApiErrorDetailModel> errors;

  const ApiErrorResponseModel({
    this.status,
    this.message,
    this.errors = const [],
  });

  factory ApiErrorResponseModel.fromJson(Map<String, dynamic> json) =>
      ApiErrorResponseModel(
        status: json['status'] as int?,
        message: json['message'] as String?,
        errors: (json['errors'] as List<dynamic>?)
                ?.map(
                  (e) =>
                      ApiErrorDetailModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      );
}
