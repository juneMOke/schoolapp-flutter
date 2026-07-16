import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

part 'enrollment_sync_api.g.dart';

/// Interface Dart du commit d'inscription (contrat `openapi_enrollment_sync`).
/// `POST /api/v1/sync/enrollments` : UN agrégat {enrollment, student, parents},
/// idempotent sur `enrollment.id`. 201/200 → réponse canonique
/// [EnrollmentAggregateResponse] ; 422 → rejet terminal (DioException, géré par
/// le handler). Le token porte le `school_id` (jamais dans le payload).
@RestApi()
abstract class EnrollmentSyncApi {
  factory EnrollmentSyncApi(Dio dio, {String baseUrl}) = _EnrollmentSyncApi;

  @POST(AppConstants.syncEnrollmentsEndpoint)
  Future<EnrollmentAggregateResponse> submit(
    @Extras() Map<String, dynamic> extras,
    @Body() EnrollmentAggregateRequest aggregate,
  );
}
