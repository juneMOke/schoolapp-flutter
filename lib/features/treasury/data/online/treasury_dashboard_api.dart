import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';

/// Le tableau de bord de la trésorerie, sur Dio : lecture seule, en ligne.
class TreasuryDashboardApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const TreasuryDashboardApi(this._dio, this._extras);

  Options get _options => Options(extra: _extras);

  Future<TreasuryOverview> overview() async {
    final response = await _dio.get<Object?>(
      AppConstants.treasuryOverviewEndpoint,
      options: _options,
    );
    return TreasuryWire.overviewFromJson(response.data);
  }

  Future<TreasuryEvolution> evolution(
    EvolutionPeriod period, {
    DateTime? from,
    DateTime? to,
  }) async {
    final custom = period == EvolutionPeriod.custom;
    final response = await _dio.get<Object?>(
      AppConstants.treasuryEvolutionEndpoint,
      queryParameters: {
        'period': period.wire,
        if (custom && from != null) 'from': TreasuryWire.dayParam(from),
        if (custom && to != null) 'to': TreasuryWire.dayParam(to),
      },
      options: _options,
    );
    return TreasuryWire.evolutionFromJson(response.data);
  }
}
