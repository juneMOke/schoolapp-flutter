import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academic_year/data/models/enrollment_academic_info_response_model.dart';
import 'package:school_app_flutter/features/academic_year/data/models/update_enrollment_academic_info_request.dart';

part 'enrollment_academic_info_remote_data_source.g.dart';

@RestApi()
abstract class EnrollmentAcademicInfoRemoteDataSource {
  factory EnrollmentAcademicInfoRemoteDataSource(Dio dio, {String baseUrl}) =
      _EnrollmentAcademicInfoRemoteDataSource;

  @PUT(AppConstants.enrollmentAcademicInfoEndpoint)
  Future<EnrollmentAcademicInfoResponseModel> updateEnrollmentAcademicInfo(
    @Extras() Map<String, dynamic> extras,
    @Path('enrollmentId') String enrollmentId,
    @Body() UpdateEnrollmentAcademicInfoRequest request,
  );
}
