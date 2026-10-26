import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

part 'payroll_dashboard_api.g.dart';

/// Surface réseau du tableau de bord de la paie — **lecture seule** : jamais
/// d'écriture, jamais d'outbox ; son échec ne coûte qu'un affichage.
///
/// Le corps se lit brut (`dynamic`) : [PayrollDashboardJson] le confie à la
/// main, comme le tableau de bord du personnel.
@RestApi()
abstract class PayrollDashboardApi {
  factory PayrollDashboardApi(Dio dio, {String baseUrl}) = _PayrollDashboardApi;

  /// Retrofit omet un paramètre `null` : sans recherche, `q` ne part pas.
  @GET(AppConstants.payrollDashboardEndpoint)
  Future<dynamic> dashboard(
    @Extras() Map<String, dynamic> extras,
    @Path('month') String month,
    @Query('filter') String filter,
    @Query('q') String? query,
  );
}
