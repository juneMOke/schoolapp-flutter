import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

part 'enrollment_sync_api.g.dart';

/// Interface Dart de l'endpoint agrégat d'inscription (F-Lot 4).
/// `POST /api/v1/sync/enrollments` : 1..N agrégats en attente, 1 ACK par item
/// corrélé par `clientEnrollmentId`. Le token porte le `school_id` (jamais dans
/// le payload).
@RestApi()
abstract class EnrollmentSyncApi {
  factory EnrollmentSyncApi(Dio dio, {String baseUrl}) = _EnrollmentSyncApi;

  @POST(AppConstants.syncEnrollmentsEndpoint)
  Future<EnrollmentCommitResult> commit(
    @Extras() Map<String, dynamic> extras,
    @Body() EnrollmentCommitBatch batch,
  );
}
