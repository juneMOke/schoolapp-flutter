import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_pull_models.dart';

part 'classroom_member_pull_api.g.dart';

/// Client du PULL KEYSET du roster (CF2, `GET /sync/classroom-members`,
/// ADR-008/009) — ressource **indépendante** de [ClassroomPullApi] (curseur
/// séparé, pas de synchro artificielle entre les deux flux).
///
/// [HttpResponse] pour exposer le statut (le `304 Not Modified` applicatif —
/// cycle vide, sans corps — arrive comme une [DioException] de statut 304).
/// Jeton `cursor` opaque base64url renvoyé VERBATIM. Cadré à l'année. `limit`
/// borné [1, 500] (défaut 100). Périmètre (école) porté par le JWT.
@RestApi()
abstract class ClassroomMemberPullApi {
  factory ClassroomMemberPullApi(Dio dio, {String baseUrl}) =
      _ClassroomMemberPullApi;

  @GET(AppConstants.syncClassroomMembersEndpoint)
  Future<HttpResponse<ClassroomMemberPageDto>> pullMembers(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String academicYearId,
  );
}
