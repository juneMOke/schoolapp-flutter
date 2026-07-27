import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_pull_models.dart';

part 'classroom_pull_api.g.dart';

/// Client du PULL KEYSET des classes (CF2, re-contracté 2026-07-27,
/// `GET /sync/classrooms`, ADR-008/009).
///
/// [HttpResponse] pour exposer le statut (le `304 Not Modified` applicatif —
/// cycle vide, sans corps — arrive comme une [DioException] de statut 304).
/// Jeton `cursor` opaque base64url renvoyé VERBATIM. Cadré à l'année. `limit`
/// borné [1, 500] (défaut 100). Périmètre (école) porté par le JWT.
@RestApi()
abstract class ClassroomPullApi {
  factory ClassroomPullApi(Dio dio, {String baseUrl}) = _ClassroomPullApi;

  @GET(AppConstants.syncClassroomsEndpoint)
  Future<HttpResponse<ClassroomPageDto>> pullClassrooms(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String academicYearId,
  );
}
