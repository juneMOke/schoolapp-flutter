import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_closure_models.dart';

part 'attendance_closure_api.g.dart';

/// Les clôtures de mois de l'appel : le geste (POST, `attendance.amend`) et
/// la descente keyset (GET, `attendance.read`).
@RestApi()
abstract class AttendanceClosureApi {
  factory AttendanceClosureApi(Dio dio, {String baseUrl}) =
      _AttendanceClosureApi;

  @POST(AppConstants.syncAttendanceClosuresEndpoint)
  Future<AttendanceClosureDto> submitClosure(
    @Extras() Map<String, dynamic> extras,
    @Body() AttendanceClosureRequestModel closure,
  );

  @GET(AppConstants.syncAttendanceClosuresEndpoint)
  Future<HttpResponse<AttendanceClosurePageDto>> pullClosures(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
