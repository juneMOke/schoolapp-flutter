import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

part 'sync_plan_api.g.dart';

/// Client du plan de synchronisation (ADR-015 F2).
@RestApi()
abstract class SyncPlanApi {
  factory SyncPlanApi(Dio dio, {String baseUrl}) = _SyncPlanApi;

  /// Le plan du porteur de session.
  ///
  /// ⚠️ **Le corps est volontairement `dynamic`, pas un DTO typé.** Retrofit
  /// délègue la désérialisation à Dio, qui caste le corps vers le type demandé :
  /// un portail captif répondant 200 en HTML ferait alors lever *à l'intérieur*
  /// de Dio, l'exception serait ré-emballée en `DioException`, et notre code ne
  /// verrait jamais le corps. La validation positive — le cœur de ce lot — ne
  /// s'exercerait nulle part, et le cas ne serait même pas testable autrement
  /// qu'en fabriquant un symptôme.
  ///
  /// Le corps brut remonte donc tel quel, et `parseSyncPlan` décide seul si
  /// c'est un plan.
  @GET(AppConstants.syncPlanEndpoint)
  Future<HttpResponse<dynamic>> getPlan(@Extras() Map<String, dynamic> extras);
}
