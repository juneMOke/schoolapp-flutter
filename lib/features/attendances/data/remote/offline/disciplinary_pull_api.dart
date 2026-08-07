import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_pull_models.dart';

part 'disciplinary_pull_api.g.dart';

/// Client du PULL KEYSET de la Discipline — miroir *lecture* de
/// `openapi_discipline_sync.yaml` (`GET /sync/disciplinary-cases`, ADR-008/009).
///
/// [HttpResponse] pour exposer le statut à l'appelant (le `304 Not Modified`
/// applicatif — cycle vide, sans corps — arrive comme une [DioException] de
/// statut 304, idiome socle). Jeton `cursor` **opaque base64url** renvoyé
/// VERBATIM. Cadré à l'**année**. `limit` borné [1, 500] (défaut 100). Le
/// périmètre (école) et la visibilité par rôle sont portés par le JWT.
@RestApi()
abstract class DisciplinaryPullApi {
  factory DisciplinaryPullApi(Dio dio, {String baseUrl}) = _DisciplinaryPullApi;

  /// Cas disciplinaires (commentaires imbriqués). `studentId` optionnel =
  /// restreint à un élève (rafraîchissement ciblé).
  @GET(AppConstants.syncDisciplinaryCasesEndpoint)
  Future<HttpResponse<DisciplinaryCasePageDto>> pullDisciplinaryCases(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String? academicYearId,
    @Query('studentId') String? studentId,
  );
}
