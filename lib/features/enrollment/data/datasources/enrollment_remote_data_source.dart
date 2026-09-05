import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_summary_page_model.dart';

part 'enrollment_remote_data_source.g.dart';

@RestApi()
abstract class EnrollmentRemoteDataSource {
  factory EnrollmentRemoteDataSource(Dio dio, {String baseUrl}) =
      _EnrollmentRemoteDataSource;

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

  /// Les statistiques d'inscription sur une fenêtre de temps.
  ///
  /// `date` n'accompagne QUE `period=day`, `from`/`to` QUE `period=custom` :
  /// le serveur refuse les autres combinaisons en 400 plutôt que d'ignorer un
  /// paramètre hors sujet. `EnrollmentStatsWindow` rend ces requêtes
  /// inconstructibles, il n'y a donc rien à valider ici.
  ///
  /// Retrofit omet les `@Query` nuls : les trois restent absents de l'URL tant
  /// que la fenêtre ne les porte pas.
  @GET(AppConstants.enrollmentStatsEndpoint)
  Future<EnrollmentStatsResponseModel> getEnrollmentStats(
    @Extras() Map<String, dynamic> extras,
    @Query('period') String period,
    @Query('date') String? date,
    @Query('from') String? from,
    @Query('to') String? to,
  );
}
