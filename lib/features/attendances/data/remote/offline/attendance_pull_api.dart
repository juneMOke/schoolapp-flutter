import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_pull_models.dart';

part 'attendance_pull_api.g.dart';

/// Client du PULL KEYSET de la Présence — miroir *lecture* de
/// `openapi_attendance_sync.yaml` (`GET /sync/attendance`, ADR-008/009).
///
/// [HttpResponse] pour exposer le statut à l'appelant (le `304 Not Modified`
/// applicatif — cycle vide, sans corps — arrive comme une [DioException] de
/// statut 304, idiome socle). Jeton `cursor` **opaque base64url** renvoyé
/// VERBATIM. Cadré à l'**année entière** (dénominateur des stats). `limit` borné
/// [1, 500] (défaut 100). Le périmètre (école) est porté par le JWT.
@RestApi()
abstract class AttendancePullApi {
  factory AttendancePullApi(Dio dio, {String baseUrl}) = _AttendancePullApi;

  /// Sessions d'appel (absences imbriquées). `classroomId` optionnel = restreint
  /// à une classe (rafraîchissement ciblé).
  @GET(AppConstants.syncAttendanceEndpoint)
  Future<HttpResponse<AttendanceSessionPageDto>> pullAttendance(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String? academicYearId,
    @Query('classroomId') String? classroomId,
  );
}
