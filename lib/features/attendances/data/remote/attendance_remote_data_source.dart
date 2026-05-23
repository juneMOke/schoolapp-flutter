import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_record_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/daily_attendance_command_model.dart';

part 'attendance_remote_data_source.g.dart';

@RestApi()
abstract class AttendanceRemoteDataSource {
  factory AttendanceRemoteDataSource(Dio dio, {String baseUrl}) =
      _AttendanceRemoteDataSource;

  @GET(AppConstants.attendanceByClassroomEndpoint)
  Future<List<AttendanceRecordModel>> listAttendanceForClass(
    @Extras() Map<String, dynamic> extras,
    @Path('classroomId') String classroomId,
    @Query('date') String date,
    @Query('academicYearId') String academicYearId,
  );

  @POST(AppConstants.attendanceEndpoint)
  Future<void> recordDailyAttendance(
    @Extras() Map<String, dynamic> extras,
    @Body() DailyAttendanceCommandModel command,
  );
}
