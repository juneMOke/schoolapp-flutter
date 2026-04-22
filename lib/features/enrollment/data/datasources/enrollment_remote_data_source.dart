import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment/data/models/create_enrollment_request_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_summary_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/update_enrollment_status_request_model.dart';

part 'enrollment_remote_data_source.g.dart';

@RestApi()
abstract class EnrollmentRemoteDataSource {
  factory EnrollmentRemoteDataSource(Dio dio, {String baseUrl}) =
      _EnrollmentRemoteDataSource;

  @POST(AppConstants.enrollmentStudentSummaryEndpoint)
  Future<EnrollmentSummaryModel> createEnrollment(
    @Extras() Map<String, dynamic> extras,
    @Body() CreateEnrollmentRequestModel request,
  );

  @PUT(AppConstants.enrollmentStatusUpdateEndpoint)
  Future<EnrollmentSummaryModel> updateEnrollmentStatus(
    @Extras() Map<String, dynamic> extras,
    @Path('enrollmentId') String enrollmentId,
    @Query('status') String status,
  );

  @GET(AppConstants.enrollmentEndpoint)
  Future<List<EnrollmentSummaryModel>>
  getEnrollmentSummaryByStatusAndAcademicYear(
    @Extras() Map<String, dynamic> extras,
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
  );

  @GET(AppConstants.enrollmentSearchByStudentInfoEndpoint)
  Future<List<EnrollmentSummaryModel>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentName(
    @Extras() Map<String, dynamic> extras,
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
    @Query('firstName') String firstName,
    @Query('lastName') String lastName,
    @Query('surname') String surname,
  );

  @GET(AppConstants.enrollmentSearchByStudentInfoWithDateOfBirthEndpoint)
  Future<List<EnrollmentSummaryModel>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirth(
    @Extras() Map<String, dynamic> extras,
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
    @Query('firstName') String firstName,
    @Query('lastName') String lastName,
    @Query('surname') String surname,
    @Query('dateOfBirth') String dateOfBirth,
  );

  @GET(AppConstants.enrollmentSearchByDateOfBirthEndpoint)
  Future<List<EnrollmentSummaryModel>>
  searchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirth(
    @Extras() Map<String, dynamic> extras,
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
    @Query('dateOfBirth') String dateOfBirth,
  );

  @GET(AppConstants.enrollmentSearchByAcademicInfoEndpoint)
  Future<List<EnrollmentSummaryModel>> searchEnrollmentSummaryByAcademicInfo(
    @Extras() Map<String, dynamic> extras,
    @Query('firstName') String firstName,
    @Query('lastName') String lastName,
    @Query('surname') String surname,
    @Query('schoolLevelGroupId') String schoolLevelGroupId,
    @Query('schoolLevelId') String schoolLevelId,
  );

  @GET(AppConstants.enrollmentPreviewByStudentEndpoint)
  Future<EnrollmentDetailModel> getEnrollmentPreviewByStudentId(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
  );

  @GET(AppConstants.enrollmentDetailEndpoint)
  Future<EnrollmentDetailModel> getEnrollmentDetail(
    @Extras() Map<String, dynamic> extras,
    @Path('enrollmentId') String enrollmentId,
  );
}
