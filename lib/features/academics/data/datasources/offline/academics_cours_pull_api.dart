import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_cours_pull_models.dart';

part 'academics_cours_pull_api.g.dart';

/// Client du PULL KEYSET des cours (référence read-only) — miroir *lecture* du
/// contrat `GET /sync/academics/cours`. Scopé **enseignant dérivé du token**
/// (commit back `1ec6be3`, DF-K) : un seul curseur, aucun `classroomId` côté
/// client. `404` = compte non lié à un enseignant. Le `304 Not Modified`
/// applicatif arrive comme une [DioException] 304 (idiome socle) — d'où
/// [HttpResponse].
@RestApi()
abstract class AcademicsCoursPullApi {
  factory AcademicsCoursPullApi(Dio dio, {String baseUrl}) =
      _AcademicsCoursPullApi;

  @GET(AppConstants.syncAcademicsCoursEndpoint)
  Future<HttpResponse<CoursPageDto>> pullCours(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
