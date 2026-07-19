import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_cours_pull_models.dart';

part 'academics_cours_pull_api.g.dart';

/// Client du PULL KEYSET des cours (référence read-only) — miroir *lecture* du
/// contrat `GET /sync/academics/cours?classroomId=`. Scopé **classe** : le
/// curseur `cursor` (opaque, renvoyé VERBATIM) est propre à chaque classe. Le
/// `304 Not Modified` applicatif arrive comme une [DioException] 304 (idiome
/// socle) — d'où [HttpResponse].
@RestApi()
abstract class AcademicsCoursPullApi {
  factory AcademicsCoursPullApi(Dio dio, {String baseUrl}) =
      _AcademicsCoursPullApi;

  @GET(AppConstants.syncAcademicsCoursEndpoint)
  Future<HttpResponse<CoursPageDto>> pullCours(
    @Extras() Map<String, dynamic> extras,
    @Query('classroomId') String classroomId,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
