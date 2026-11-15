import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_adjustment.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Les caisses de l'école et leurs ajustements, sur Dio.
class CashRegistersApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const CashRegistersApi(this._dio, this._extras);

  Options get _options => Options(extra: _extras);

  Future<List<RegisterConfig>> list() async {
    final response = await _dio.get<Object?>(
      AppConstants.treasuryCashRegistersEndpoint,
      options: _options,
    );
    return TreasuryWire.registerConfigsFromJson(response.data);
  }

  Future<CashRegister> create({
    required TreasuryCurrency currency,
    required String? name,
    required int openingAmountInCents,
  }) async {
    final response = await _dio.post<Object?>(
      AppConstants.treasuryCashRegistersEndpoint,
      data: TreasuryWire.createRegisterToJson(
        currency: currency,
        name: name,
        openingAmountInCents: openingAmountInCents,
      ),
      options: _options,
    );
    return TreasuryWire.registerFromJson(response.data);
  }

  Future<CashAdjustment> adjust({
    required String registerId,
    required String id,
    required int shownExpectedInCents,
    required int newAmountInCents,
    required String reason,
  }) async {
    final response = await _dio.post<Object?>(
      _adjustments(registerId),
      data: TreasuryWire.adjustmentToJson(
        id: id,
        shownExpectedInCents: shownExpectedInCents,
        newAmountInCents: newAmountInCents,
        reason: reason,
      ),
      options: _options,
    );
    return TreasuryWire.adjustmentOfResponse(response.data);
  }

  Future<List<CashAdjustment>> adjustments(String registerId) async {
    final response = await _dio.get<Object?>(
      _adjustments(registerId),
      options: _options,
    );
    return TreasuryWire.adjustmentsFromJson(response.data);
  }

  static String _adjustments(String registerId) => AppConstants
      .treasuryCashRegisterAdjustmentsEndpoint
      .replaceFirst('{registerId}', Uri.encodeComponent(registerId));
}
