import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_lock_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_settings_dto.dart';

part 'staff_attendance_sync_api.g.dart';

/// Les routes de synchronisation du Pointage du personnel.
///
/// **Un envoi par requête** — un pointage, un geste, un réglage — : l'issue
/// d'une ligne est le statut HTTP de sa réponse, et son refus se lit dans le
/// `detailCode`.
@RestApi()
abstract class StaffAttendanceSyncApi {
  factory StaffAttendanceSyncApi(Dio dio, {String baseUrl}) =
      _StaffAttendanceSyncApi;

  /// Un pointage (création, modification, effacement), idempotent par son
  /// uuid5, arbitré au dernier écrit.
  @POST(AppConstants.syncStaffAttendanceEndpoint)
  Future<StaffAttendanceSyncResponseDto> submitAttendance(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  /// Un geste de verrou, idempotent par son `gestureId`. Rend l'état.
  @POST(AppConstants.syncStaffAttendanceLocksEndpoint)
  Future<StaffAttendanceLockDto> submitGesture(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  /// Les réglages de l'école, dernier écrit gagne. Rend ceux que le serveur
  /// a retenus.
  @PUT(AppConstants.syncStaffAttendanceSettingsEndpoint)
  Future<StaffAttendanceSettingsResponseDto> putSettings(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  @GET(AppConstants.syncStaffAttendanceEndpoint)
  Future<HttpResponse<StaffAttendancePageDto>> pullAttendance(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @GET(AppConstants.syncStaffAttendanceLocksEndpoint)
  Future<HttpResponse<StaffAttendanceLockPageDto>> pullLocks(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
