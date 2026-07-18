import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_aggregate_response_model.dart';

part 'disciplinary_sync_api.g.dart';

/// Client de push de l'agrégat disciplinaire (DF-2) — `{case, comments[]}` vers
/// `POST /api/v1/sync/disciplinary-cases` (contrat 1.1.0). Upsert idempotent côté
/// serveur (uuid du cas + LWW `clientUpdatedAt` ; commentaires dédupliqués par
/// uuid). La réponse porte `lwwOutcome` + l'état canonique. Datasource dédiée
/// offline : n'altère pas le contrat online.
@RestApi()
abstract class DisciplinarySyncApi {
  factory DisciplinarySyncApi(Dio dio, {String baseUrl}) = _DisciplinarySyncApi;

  /// Pousse un agrégat disciplinaire (création ou évolution).
  @POST(AppConstants.syncDisciplinaryCasesEndpoint)
  Future<DisciplinaryCaseAggregateResponseModel> submitDisciplinaryCase(
    @Extras() Map<String, dynamic> extras,
    @Body() DisciplinaryCaseAggregateRequestModel aggregate,
  );
}
