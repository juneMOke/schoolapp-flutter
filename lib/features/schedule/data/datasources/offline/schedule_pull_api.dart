import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/schedule_pull_models.dart';

part 'schedule_pull_api.g.dart';

/// Client du PULL KEYSET de l'emploi du temps (référence read-only) — miroir
/// *lecture* du contrat `GET /sync/schedule/time-slots` (scope école, JWT) et
/// `GET /sync/schedule/sessions` (scope année). Jeton `cursor` **opaque**
/// renvoyé VERBATIM. Le `304 Not Modified` applicatif (cycle vide, sans corps)
/// arrive comme une [DioException] de statut 304 (idiome socle) — d'où
/// [HttpResponse].
@RestApi()
abstract class SchedulePullApi {
  factory SchedulePullApi(Dio dio, {String baseUrl}) = _SchedulePullApi;

  /// Trame horaire de l'école. Périmètre (école) porté par le JWT.
  @GET(AppConstants.syncScheduleTimeSlotsEndpoint)
  Future<HttpResponse<TimeSlotPageDto>> pullTimeSlots(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  /// Séances récurrentes de l'année. `academicYearId` null = année active
  /// (défaut serveur).
  @GET(AppConstants.syncScheduleSessionsEndpoint)
  Future<HttpResponse<RecurringSessionPageDto>> pullSessions(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String? academicYearId,
  );
}
