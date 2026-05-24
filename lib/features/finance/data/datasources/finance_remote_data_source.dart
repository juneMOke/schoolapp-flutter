import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/data/models/fee_tariff_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model.dart';

part 'finance_remote_data_source.g.dart';

@RestApi()
abstract class FinanceRemoteDataSource {
  factory FinanceRemoteDataSource(Dio dio, {String baseUrl}) =
      _FinanceRemoteDataSource;

  @GET(AppConstants.feeTariffsEndpoint)
  Future<List<FeeTariffModel>> listTariffsByLevel(
    @Extras() Map<String, dynamic> extras,
    @Query('levelId') String levelId,
  );

  @GET(AppConstants.financeStatsEndpoint)
  Future<FinanceStatsResponseModel> getFinanceStats(
    @Extras() Map<String, dynamic> extras,
    @Query('period') String period,
    @Query('month') String? month,
    @Query('week') String? week,
  );
}
