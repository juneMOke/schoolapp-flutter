import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/attendance_overview_response_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/student_attendance_summary_model.dart';

part 'attendance_stats_remote_data_source.g.dart';

@RestApi()
abstract class AttendanceStatsRemoteDataSource {
  factory AttendanceStatsRemoteDataSource(Dio dio, {String baseUrl}) =
      _AttendanceStatsRemoteDataSource;

  @GET(AppConstants.attendanceStudentSummaryEndpoint)
  Future<StudentAttendanceSummaryModel> getStudentAttendanceSummary(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Query('period') String period,
    @Query('month') String? month,
    @Query('week') String? week,
  );

  @GET(AppConstants.attendanceOverviewEndpoint)
  Future<AttendanceOverviewResponseModel> getAttendanceOverview(
    @Extras() Map<String, dynamic> extras,
    @Query('period') String period,
    @Query('month') String? month,
    @Query('week') String? week,
  );
}
