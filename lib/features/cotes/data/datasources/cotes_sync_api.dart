import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_push_models.dart';

part 'cotes_sync_api.g.dart';

/// L'envoi d'un lot de cotes : toujours un 200, un résultat par ligne.
@RestApi()
abstract class CotesSyncApi {
  factory CotesSyncApi(Dio dio, {String baseUrl}) = _CotesSyncApi;

  @POST(AppConstants.syncAcademicsCotesEndpoint)
  Future<CotesPushResponse> submit(
    @Extras() Map<String, dynamic> extras,
    @Body() CotesPushRequest request,
  );
}
