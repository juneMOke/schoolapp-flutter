import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_push_models.dart';

part 'academics_evaluation_sync_api.g.dart';

/// Client de push d'une évaluation (régime A) — `{authorId?, evaluation}` vers
/// `POST /api/v1/sync/academics/evaluations`. Idempotent côté serveur (uuid
/// client honoré, `ON CONFLICT (id) DO NOTHING`) : 201 créée ≡ 200 rejeu, les
/// deux succès. Datasource dédiée offline : n'altère pas le contrat online.
@RestApi()
abstract class AcademicsEvaluationSyncApi {
  factory AcademicsEvaluationSyncApi(Dio dio, {String baseUrl}) =
      _AcademicsEvaluationSyncApi;

  @POST(AppConstants.syncAcademicsEvaluationsEndpoint)
  Future<EvaluationPushResponseModel> submitEvaluation(
    @Extras() Map<String, dynamic> extras,
    @Body() EvaluationPushRequestModel request,
  );
}
