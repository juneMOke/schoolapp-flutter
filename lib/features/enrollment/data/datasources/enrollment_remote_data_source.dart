import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment/data/models/school_level_group_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/school_level_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/student_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/student_summary_model.dart';

part 'enrollment_remote_data_source.g.dart';

@RestApi()
abstract class EnrollmentRemoteDataSource {
  factory EnrollmentRemoteDataSource(Dio dio, {String baseUrl}) =
      _EnrollmentRemoteDataSource;

  @GET(AppConstants.preRegistrationsEndpoint)
  Future<List<StudentSummaryModel>> getPreRegistrations(
    @Query('status') String status,
    @Query('academicYearId') String academicYearId,
  );

  @GET(AppConstants.studentsSearchEndpoint)
  Future<List<StudentSummaryModel>> searchStudents(
    @Query('firstName') String? firstName,
    @Query('lastName') String? lastName,
    @Query('middleName') String? middleName,
    @Query('academicYearId') String academicYearId,
  );

  @GET(AppConstants.studentDetailEndpoint)
  Future<StudentDetailModel> getStudentDetail(
    @Path('enrollmentId') String enrollmentId,
  );

  @GET(AppConstants.schoolLevelGroupsEndpoint)
  Future<List<SchoolLevelGroupModel>> getSchoolLevelGroups(
    @Query('academicYearId') String academicYearId,
  );

  @GET(AppConstants.schoolLevelsEndpoint)
  Future<List<SchoolLevelModel>> getSchoolLevels(
    @Query('levelGroupId') String levelGroupId,
    @Query('academicYearId') String academicYearId,
  );

  @GET(AppConstants.academicFeesEndpoint)
  Future<Map<String, dynamic>> getAcademicFees(
    @Query('levelId') String levelId,
    @Query('academicYearId') String academicYearId,
    @Query('page') int page,
    @Query('size') int size,
  );
}
