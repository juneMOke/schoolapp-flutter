import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';

part 'academics_metier_pull_api.g.dart';

/// Client du PULL KEYSET métier — évaluations et notes, **scopés cours**,
/// **curseurs indépendants** (split assumé, cf. contrat). Jeton `cursor` opaque
/// renvoyé VERBATIM ; `304 Not Modified` applicatif → [DioException] 304.
@RestApi()
abstract class AcademicsMetierPullApi {
  factory AcademicsMetierPullApi(Dio dio, {String baseUrl}) =
      _AcademicsMetierPullApi;

  @GET(AppConstants.syncAcademicsEvaluationsEndpoint)
  Future<HttpResponse<EvaluationPageDto>> pullEvaluations(
    @Extras() Map<String, dynamic> extras,
    @Query('coursId') String coursId,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @GET(AppConstants.syncAcademicsNotesEndpoint)
  Future<HttpResponse<NotePageDto>> pullNotes(
    @Extras() Map<String, dynamic> extras,
    @Query('coursId') String coursId,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
