import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academic_year/data/models/academic_year_model.dart';

part 'academic_year_remote_data_source.g.dart';

@RestApi()
abstract class AcademicYearRemoteDataSource {
  factory AcademicYearRemoteDataSource(Dio dio, {String baseUrl}) =
      _AcademicYearRemoteDataSource;

  @GET(AppConstants.academicYearBySchoolEndpoint)
  Future<AcademicYearModel> getAcademicYearBySchoolId(
    @Extras() Map<String, dynamic> extras,
    @Query('schoolId') String schoolId,
  );
}