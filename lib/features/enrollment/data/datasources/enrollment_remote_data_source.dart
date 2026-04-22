import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment/data/models/create_enrollment_request_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_summary_page_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_summary_model.dart';

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
  Future<EnrollmentSummaryPageModel>
  getEnrollmentSummaryByStatusAndAcademicYear(
    @Extras() Map<String, dynamic> extras,
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
    @Query('page') int page,
    @Query('size') int size,
  );

  @GET(AppConstants.enrollmentSearchByStudentInfoEndpoint)
  Future<EnrollmentSummaryPageModel>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentName(
    @Extras() Map<String, dynamic> extras,
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
    @Query('firstName') String firstName,
    @Query('lastName') String lastName,
    @Query('surname') String surname,
    @Query('page') int page,
    @Query('size') int size,
  );

  @GET(AppConstants.enrollmentSearchByStudentInfoWithDateOfBirthEndpoint)
  Future<EnrollmentSummaryPageModel>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirth(
    @Extras() Map<String, dynamic> extras,
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
    @Query('firstName') String firstName,
    @Query('lastName') String lastName,
    @Query('surname') String surname,
    @Query('dateOfBirth') String dateOfBirth,
    @Query('page') int page,
    @Query('size') int size,
  );

  @GET(AppConstants.enrollmentSearchByDateOfBirthEndpoint)
  Future<EnrollmentSummaryPageModel>
  searchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirth(
    @Extras() Map<String, dynamic> extras,
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
    @Query('dateOfBirth') String dateOfBirth,
    @Query('page') int page,
    @Query('size') int size,
  );

  @GET(AppConstants.enrollmentSearchByAcademicInfoEndpoint)
  Future<EnrollmentSummaryPageModel> searchEnrollmentSummaryByAcademicInfo(
    @Extras() Map<String, dynamic> extras,
    @Query('firstName') String firstName,
    @Query('lastName') String lastName,
    @Query('surname') String surname,
    @Query('schoolLevelGroupId') String schoolLevelGroupId,
    @Query('schoolLevelId') String schoolLevelId,
    @Query('page') int page,
    @Query('size') int size,
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
