import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';

/// La journée de caisse et ses gestes (clôture, réponse aux lignes arrivées
/// après une clôture, réouverture), sur Dio.
class TreasuryDayApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const TreasuryDayApi(this._dio, this._extras);

  Options get _options => Options(extra: _extras);

  Future<TreasuryDay> day(DateTime date) async {
    final response = await _dio.get<Object?>(
      _withDate(AppConstants.treasuryDayEndpoint, date),
      options: _options,
    );
    return TreasuryWire.dayFromJson(response.data);
  }

  Future<List<CashMovement>> movements(
    DateTime date, {
    required String registerId,
    MovementDirection? direction,
  }) async {
    final response = await _dio.get<Object?>(
      _withDate(AppConstants.treasuryDayMovementsEndpoint, date),
      queryParameters: {
        'registerId': registerId,
        if (direction != null) 'direction': direction.wire,
      },
      options: _options,
    );
    return TreasuryWire.movementsFromJson(response.data);
  }

  Future<CashClosure> close(
    DateTime date, {
    required String id,
    required String registerId,
    required bool matches,
    required int shownExpectedInCents,
    int? declaredAmountInCents,
    String? justification,
  }) async {
    final response = await _dio.post<Object?>(
      _withDate(AppConstants.treasuryDayClosuresEndpoint, date),
      data: TreasuryWire.closureToJson(
        id: id,
        registerId: registerId,
        matches: matches,
        shownExpectedInCents: shownExpectedInCents,
        declaredAmountInCents: declaredAmountInCents,
        justification: justification,
      ),
      options: _options,
    );
    return TreasuryWire.closureOfResponse(response.data);
  }

  Future<void> confirmAfterClosure(
    String movementId, {
    required String id,
    required bool alreadyCounted,
  }) => _dio.post<Object?>(
    AppConstants.treasuryAfterClosureConfirmationEndpoint.replaceFirst(
      '{movementId}',
      Uri.encodeComponent(movementId),
    ),
    data: {'id': id, 'alreadyCounted': alreadyCounted},
    options: _options,
  );

  Future<CashClosure> reopen(
    String closureId, {
    required String id,
    required String reason,
  }) async {
    final response = await _dio.post<Object?>(
      AppConstants.treasuryClosureReopeningEndpoint.replaceFirst(
        '{closureId}',
        Uri.encodeComponent(closureId),
      ),
      data: {'id': id, 'reason': reason.trim()},
      options: _options,
    );
    return TreasuryWire.closureOfResponse(response.data);
  }

  static String _withDate(String template, DateTime date) =>
      template.replaceFirst('{date}', TreasuryWire.dayParam(date));
}
