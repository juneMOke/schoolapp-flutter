import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_delta_dto.dart';

part 'cotes_pull_api.g.dart';

/// Le flux des cotes d'un cours, pour la tablette de son enseignant.
@RestApi()
abstract class CotesPullApi {
  factory CotesPullApi(Dio dio, {String baseUrl}) = _CotesPullApi;

  @GET(AppConstants.syncAcademicsCotesEndpoint)
  Future<HttpResponse<CotePageDto>> pullCotes(
    @Extras() Map<String, dynamic> extras,
    @Query('coursId') String coursId,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
