import 'dart:typed_data';

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

part 'hr_staff_dashboard_api.g.dart';

/// Surface réseau du tableau de bord du personnel — **lecture seule** : ces
/// routes ne s'écrivent jamais et ne passent jamais par l'outbox ; leur échec
/// ne coûte qu'un affichage.
///
/// Les corps JSON se lisent bruts (`dynamic`) : les modèles les confient à la
/// main, comme ceux du tableau de bord de la boutique.
@RestApi()
abstract class HrStaffDashboardApi {
  factory HrStaffDashboardApi(Dio dio, {String baseUrl}) = _HrStaffDashboardApi;

  @GET(AppConstants.hrStaffStatsEndpoint)
  Future<dynamic> getStats(@Extras() Map<String, dynamic> extras);

  /// Retrofit omet un paramètre `null` : sans recherche ni catégorie, seuls
  /// `sort`, `page` et `size` partent.
  @GET(AppConstants.hrStaffMembersEndpoint)
  Future<dynamic> getMembers(
    @Extras() Map<String, dynamic> extras,
    @Query('q') String? search,
    @Query('category') String? category,
    @Query('sort') String sort,
    @Query('page') int page,
    @Query('size') int size,
  );

  /// `HttpResponse` pour lire le nom du fichier dans `Content-Disposition` ;
  /// `ResponseType.bytes`, sans quoi Dio lirait le PDF comme du JSON ; un
  /// `Accept` qui couvre aussi le JSON d'une 400 ou d'une 429. [options] porte
  /// le délai de réception d'un rendu long.
  @GET(AppConstants.hrStaffMembersReportEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> getMembersReport(
    @Extras() Map<String, dynamic> extras,
    @Query('q') String? search,
    @Query('category') String? category,
    @Query('sort') String sort,
    @DioOptions() Options options,
  );
}
