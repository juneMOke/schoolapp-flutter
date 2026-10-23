import 'dart:typed_data';

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_beneficiaries_page_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_stats_model.dart';

part 'boutique_dashboard_api.g.dart';

/// Surface réseau du tableau de bord de la boutique — **lecture seule**.
///
/// À part de `BoutiqueSyncApi`, qui porte l'argent et sa pièce : ces routes-ci
/// ne s'écrivent jamais, ne passent jamais par l'outbox, et leur échec ne coûte
/// qu'un affichage.
@RestApi()
abstract class BoutiqueDashboardApi {
  factory BoutiqueDashboardApi(Dio dio, {String baseUrl}) =
      _BoutiqueDashboardApi;

  /// `from` / `to` : `YYYY-MM-DD`, inclus tous les deux, 366 jours au plus.
  /// Une fenêtre sans vente rend `200` et des compteurs à zéro, jamais `404`.
  @GET(AppConstants.boutiqueStatsEndpoint)
  Future<BoutiqueStatsModel> getStats(
    @Extras() Map<String, dynamic> extras,
    @Query('from') String from,
    @Query('to') String to,
    @Query('academicYearId') String academicYearId,
  );

  /// `size` est plafonné à 100 par le serveur. `totalElements`, le tri et la
  /// pagination se calculent **après** les filtres ; `classes[]`, avant.
  @GET(AppConstants.boutiqueBeneficiariesEndpoint)
  Future<BoutiqueBeneficiariesPageModel> getBeneficiaries(
    @Extras() Map<String, dynamic> extras,
    @Query('from') String from,
    @Query('to') String to,
    @Query('academicYearId') String academicYearId,
    @Query('articleId') String? articleId,
    @Query('classId') String? classId,
    @Query('q') String? search,
    @Query('page') int page,
    @Query('size') int size,
  );

  /// Les ventes de la fenêtre, 10 par page. `family` **ou** `classId` : le
  /// serveur refuse les deux ensemble en 400 — Retrofit omet le `null`, seul
  /// le critère actif part.
  ///
  /// La page se lit brute (`dynamic`, Retrofit ne décode pas un `Map` nu) :
  /// le repository la confie à `BoutiqueSalesPageModel`.
  @GET(AppConstants.boutiqueSalesEndpoint)
  Future<dynamic> getSales(
    @Extras() Map<String, dynamic> extras,
    @Query('from') String from,
    @Query('to') String to,
    @Query('academicYearId') String academicYearId,
    @Query('family') String? family,
    @Query('classId') String? classId,
    @Query('page') int page,
    @Query('size') int size,
  );

  /// Le rapport PDF (pièce VB) des mêmes ventes, sans pagination.
  ///
  /// `HttpResponse` pour lire le nom du fichier dans `Content-Disposition` ;
  /// `ResponseType.bytes`, sans quoi Dio lirait le PDF comme du JSON ; un
  /// `Accept` qui couvre aussi le JSON d'une 400 ou d'une 429. [options] porte
  /// le délai de réception d'un rendu long.
  @GET(AppConstants.boutiqueSalesReportEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> getSalesReport(
    @Extras() Map<String, dynamic> extras,
    @Query('from') String from,
    @Query('to') String to,
    @Query('academicYearId') String academicYearId,
    @Query('family') String? family,
    @Query('classId') String? classId,
    @DioOptions() Options options,
  );
}
