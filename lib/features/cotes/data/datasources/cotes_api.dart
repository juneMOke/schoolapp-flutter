import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_classe_dto.dart';

part 'cotes_api.g.dart';

/// Le chargement d'une classe : `If-None-Match` en entrée, `200` + en-tête
/// `ETag`, ou `304` sans corps (une [DioException], comme les autres ETag).
@RestApi()
abstract class CotesApi {
  factory CotesApi(Dio dio, {String baseUrl}) = _CotesApi;

  @GET(AppConstants.cotesClasseEndpoint)
  Future<HttpResponse<CoteClasseDto>> loadClasse(
    @Extras() Map<String, dynamic> extras,
    @Query('classroomId') String classroomId,
    @Header('If-None-Match') String? ifNoneMatch,
  );
}
