import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/attendance_justification_dto.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/attendance_justification_page_dto.dart';

part 'attendance_justification_api.g.dart';

/// Les justifications d'absence des parents : la descente keyset et la
/// décision de l'école, toutes deux sous `attendance.amend`.
@RestApi()
abstract class AttendanceJustificationApi {
  factory AttendanceJustificationApi(Dio dio, {String baseUrl}) =
      _AttendanceJustificationApi;

  @GET(AppConstants.syncAttendanceJustificationsEndpoint)
  Future<HttpResponse<AttendanceJustificationPageDto>> pullJustifications(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  @POST(AppConstants.syncAttendanceJustificationDecisionEndpoint)
  Future<AttendanceJustificationDto> decide(
    @Extras() Map<String, dynamic> extras,
    @Path('id') String justificationId,
    @Body() Map<String, dynamic> decision,
  );
}
