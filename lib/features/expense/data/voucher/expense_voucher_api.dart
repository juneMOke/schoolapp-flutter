import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

/// Ce que rend le serveur pour la photo d'un bon.
class ExpenseVoucherDownload {
  final Uint8List bytes;
  final String contentType;

  const ExpenseVoucherDownload({
    required this.bytes,
    required this.contentType,
  });
}

/// Relit la photo du bon d'une dépense. Écrit sur Dio et non sur Retrofit :
/// la réponse est binaire, et son type vient de l'en-tête.
class ExpenseVoucherApi {
  final Dio _dio;

  const ExpenseVoucherApi(this._dio);

  Future<ExpenseVoucherDownload> download(
    Map<String, dynamic> extras,
    String expenseId,
  ) async {
    final response = await _dio.get<List<int>>(
      AppConstants.expenseVoucherEndpoint.replaceFirst(
        '{expenseId}',
        Uri.encodeComponent(expenseId),
      ),
      options: Options(extra: extras, responseType: ResponseType.bytes),
    );
    final type = response.headers.value(Headers.contentTypeHeader);
    return ExpenseVoucherDownload(
      bytes: Uint8List.fromList(response.data ?? const []),
      // `image/jpeg; charset=…` : seul le type compte.
      contentType: (type ?? '').split(';').first.trim().toLowerCase(),
    );
  }
}
