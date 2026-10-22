import 'package:dio/dio.dart';
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
}
