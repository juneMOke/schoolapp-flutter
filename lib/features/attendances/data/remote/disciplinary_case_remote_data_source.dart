import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/create_disciplinary_case_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/disciplinary_case_detail_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/disciplinary_case_summary_model.dart';

part 'disciplinary_case_remote_data_source.g.dart';

@RestApi()
abstract class DisciplinaryCaseRemoteDataSource {
  factory DisciplinaryCaseRemoteDataSource(Dio dio, {String baseUrl}) =
      _DisciplinaryCaseRemoteDataSource;

  @GET(AppConstants.disciplinaryCasesEndpoint)
  Future<List<DisciplinaryCaseSummaryModel>>
  fetchDisciplinaryCasesByStudentAndYear(
    @Extras() Map<String, dynamic> extras,
    @Query('studentId') String studentId,
    @Query('academicYearId') String academicYearId,
  );

  @GET(AppConstants.disciplinaryCaseByIdEndpoint)
  Future<DisciplinaryCaseDetailModel> getCaseById(
    @Extras() Map<String, dynamic> extras,
    @Path('caseId') String caseId,
  );

  @POST(AppConstants.disciplinaryCasesEndpoint)
  Future<DisciplinaryCaseSummaryModel> createCase(
    @Extras() Map<String, dynamic> extras,
    @Body() CreateDisciplinaryCaseRequestModel request,
  );
}
