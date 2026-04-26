import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_model.dart';
import 'package:school_app_flutter/features/classes/data/models/distribution_request_model.dart';

part 'classroom_remote_data_source.g.dart';

@RestApi()
abstract class ClassroomRemoteDataSource {
  factory ClassroomRemoteDataSource(Dio dio, {String baseUrl}) =
      _ClassroomRemoteDataSource;

  @GET(AppConstants.classroomsEndpoint)
  Future<List<ClassroomModel>> listClassroomsByLevelAndAcademicYear(
    @Extras() Map<String, dynamic> extras,
    @Query('schoolLevelGroupId') String schoolLevelGroupId,
    @Query('schoolLevelId') String schoolLevelId,
    @Query('academicYearId') String academicYearId,
  );

  @POST(AppConstants.classroomsDistributeEndpoint)
  Future<void> distributeStudentsToClassrooms(
    @Extras() Map<String, dynamic> extras,
    @Body() DistributionRequestModel request,
  );
}
