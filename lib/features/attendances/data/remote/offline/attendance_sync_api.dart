import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_response_model.dart';

part 'attendance_sync_api.g.dart';

/// Client de push de l'appel offline (AF-2) — agrégat `{session, absences[]}`
/// vers `POST /api/v1/sync/attendance` (contrat 1.2.0). Idempotent côté serveur
/// via la **clé naturelle** + LWW ; la réponse porte `lwwOutcome` +
/// `expectedCount`. Datasource dédiée offline : n'altère pas le contrat online.
@RestApi()
abstract class AttendanceSyncApi {
  factory AttendanceSyncApi(Dio dio, {String baseUrl}) = _AttendanceSyncApi;

  /// Pousse un agrégat d'appel (session + absences exhaustives).
  @POST(AppConstants.syncAttendanceEndpoint)
  Future<AttendanceAggregateResponseModel> submitAttendance(
    @Extras() Map<String, dynamic> extras,
    @Body() AttendanceAggregateRequestModel aggregate,
  );
}
