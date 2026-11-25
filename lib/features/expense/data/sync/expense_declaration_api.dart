import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_payload.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';

/// Pousse une déclaration : **une** requête multipart, le JSON et la photo
/// ensemble — ils arrivent tous les deux ou aucun, ce qui garde la photo
/// obligatoire même hors ligne.
///
/// Écrit sur Dio et non sur Retrofit : la partie `declaration` doit partir en
/// `application/json`, ce que le générateur ne sait pas dire d'une partie.
class ExpenseDeclarationApi {
  final Dio _dio;

  const ExpenseDeclarationApi(this._dio);

  Future<ExpenseSyncResponseDto> submit(
    Map<String, dynamic> extras,
    ExpenseDeclarationPayload payload,
    Uint8List voucher,
  ) async {
    final form = FormData.fromMap({
      'declaration': MultipartFile.fromString(
        jsonEncode(payload.toWireJson()),
        contentType: DioMediaType('application', 'json'),
      ),
      'voucher': MultipartFile.fromBytes(
        voucher,
        filename: '${payload.expense.id}${_extensionOf(payload)}',
        contentType: DioMediaType.parse(payload.voucherContentType),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      AppConstants.syncExpenseDeclarationsEndpoint,
      data: form,
      options: Options(extra: extras),
    );
    return ExpenseSyncResponseDto.fromJson(response.data ?? const {});
  }

  static String _extensionOf(ExpenseDeclarationPayload payload) =>
      switch (payload.voucherContentType) {
        'application/pdf' => '.pdf',
        'image/png' => '.png',
        _ => '.jpg',
      };
}
