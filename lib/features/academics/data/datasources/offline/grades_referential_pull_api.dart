import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_pull_models.dart';

part 'grades_referential_pull_api.g.dart';

/// Client du pull **bundle** `grades-referential` (réf de saisie, lecture
/// seule), cadré **enseignant dérivé du token**. Mécanisme **ETag applicatif**
/// — pas keyset, non paginé : `If-None-Match` en entrée, `200` + en-tête `ETag`
/// (lu sur [HttpResponse.response]) ou `304` sans corps (idiome socle :
/// [DioException] 304, comme les autres pulls académiques). `404` = compte non
/// lié à un enseignant.
@RestApi()
abstract class GradesReferentialPullApi {
  factory GradesReferentialPullApi(Dio dio, {String baseUrl}) =
      _GradesReferentialPullApi;

  @GET(AppConstants.syncAcademicsGradesReferentialEndpoint)
  Future<HttpResponse<GradesReferentialBundleDto>> pullGradesReferential(
    @Extras() Map<String, dynamic> extras,
    @Header('If-None-Match') String? ifNoneMatch,
  );
}
