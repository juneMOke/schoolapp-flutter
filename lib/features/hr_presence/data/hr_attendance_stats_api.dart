import 'dart:typed_data';

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

part 'hr_attendance_stats_api.g.dart';

/// Surface réseau des statistiques de présence du personnel — **lecture
/// seule** : ces routes ne s'écrivent jamais et ne passent jamais par
/// l'outbox ; leur échec ne coûte qu'un affichage.
///
/// Les corps JSON se lisent bruts (`dynamic`) : les modèles les confient à la
/// main, comme ceux du tableau de bord du personnel.
@RestApi()
abstract class HrAttendanceStatsApi {
  factory HrAttendanceStatsApi(Dio dio, {String baseUrl}) =
      _HrAttendanceStatsApi;

  @GET(AppConstants.hrAttendanceStatsEndpoint)
  Future<dynamic> getDashboard(
    @Extras() Map<String, dynamic> extras,
    @Query('from') String from,
    @Query('to') String to,
  );

  @GET(AppConstants.hrAttendanceAgentMonthEndpoint)
  Future<dynamic> getAgentMonth(
    @Extras() Map<String, dynamic> extras,
    @Path('staffMemberId') String staffMemberId,
    @Query('month') String month,
  );

  @GET(AppConstants.hrAttendanceAgentYearEndpoint)
  Future<dynamic> getAgentYear(
    @Extras() Map<String, dynamic> extras,
    @Path('staffMemberId') String staffMemberId,
  );

  /// L'un **ou** l'autre : Retrofit omet un paramètre `null`, et le serveur
  /// refuse en 400 les deux ensemble comme aucun.
  @GET(AppConstants.hrAttendanceProfilesEndpoint)
  Future<dynamic> getProfiles(
    @Extras() Map<String, dynamic> extras,
    @Query('month') String? month,
    @Query('scope') String? scope,
  );

  @GET(AppConstants.hrAttendanceRecapEndpoint)
  Future<dynamic> getRecap(
    @Extras() Map<String, dynamic> extras,
    @Query('month') String month,
  );

  /// `HttpResponse` pour lire le nom du fichier dans `Content-Disposition` ;
  /// `ResponseType.bytes`, sans quoi Dio lirait le PDF comme du JSON ; un
  /// `Accept` qui couvre aussi le JSON d'une 400 ou d'une 429. [options] porte
  /// le délai de réception d'un rendu long.
  @GET(AppConstants.hrAttendanceReportEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> getReport(
    @Extras() Map<String, dynamic> extras,
    @Query('from') String from,
    @Query('to') String to,
    @Query('q') String? search,
    @DioOptions() Options options,
  );

  /// La liste de la fiche individuelle en PDF (pièce PR) : `month` ou
  /// `scope=year`, et les filtres de l'écran.
  @GET(AppConstants.hrAttendanceProfilesReportEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> getProfilesReport(
    @Extras() Map<String, dynamic> extras,
    @Query('month') String? month,
    @Query('scope') String? scope,
    @Query('q') String? search,
    @Query('category') String? category,
    @Query('profile') String? profile,
    @DioOptions() Options options,
  );

  /// La fiche de présence du mois d'un agent : FP scellée (mois clos) ou
  /// provisoire — le serveur choisit.
  @GET(AppConstants.hrAttendanceAgentMonthSheetEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> getAgentMonthSheet(
    @Extras() Map<String, dynamic> extras,
    @Path('staffMemberId') String staffMemberId,
    @Query('month') String month,
  );

  /// La fiche de présence de l'année d'un agent — provisoire en V1.
  @GET(AppConstants.hrAttendanceAgentYearSheetEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> getAgentYearSheet(
    @Extras() Map<String, dynamic> extras,
    @Path('staffMemberId') String staffMemberId,
  );
}
