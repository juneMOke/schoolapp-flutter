import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_daily_attendance_command_model.dart';

part 'attendance_sync_api.g.dart';

/// Client de push de l'appel offline (AF-2). Réutilise `POST /api/v1/attendances`
/// (upsert clé naturelle) mais avec la commande enrichie `updatedAt` (LWW, AG-2).
/// Datasource dédiée offline : n'altère pas le contrat online existant.
@RestApi()
abstract class AttendanceSyncApi {
  factory AttendanceSyncApi(Dio dio, {String baseUrl}) = _AttendanceSyncApi;

  /// Pousse l'état complet d'un appel (full-write). Idempotent côté serveur via
  /// la clé naturelle `(student, date, année)` + LWW `updatedAt`.
  @POST(AppConstants.attendanceEndpoint)
  Future<void> pushDailyAttendance(
    @Extras() Map<String, dynamic> extras,
    @Body() OfflineDailyAttendanceCommandModel command,
  );
}
