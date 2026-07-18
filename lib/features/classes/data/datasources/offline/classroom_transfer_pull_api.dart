import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_pull_models.dart';

part 'classroom_transfer_pull_api.g.dart';

/// Client du PULL KEYSET des transferts — miroir *lecture* de
/// `openapi_classroom_sync.yaml` 1.1.0 (`GET /sync/classroom-transfers`,
/// ADR-008/009).
///
/// [HttpResponse] pour exposer le statut (le `304 Not Modified` applicatif —
/// cycle vide, sans corps — arrive comme une [DioException] de statut 304).
/// Jeton `cursor` opaque base64url renvoyé VERBATIM. Cadré à l'année. `limit`
/// borné [1, 500] (défaut 100). Périmètre (école) porté par le JWT.
@RestApi()
abstract class ClassroomTransferPullApi {
  factory ClassroomTransferPullApi(Dio dio, {String baseUrl}) =
      _ClassroomTransferPullApi;

  /// `studentId` optionnel = restreindre à un élève (rafraîchissement ciblé).
  @GET(AppConstants.syncClassroomTransfersEndpoint)
  Future<HttpResponse<ClassroomTransferPageDto>> pullTransfers(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String? academicYearId,
    @Query('studentId') String? studentId,
  );
}
