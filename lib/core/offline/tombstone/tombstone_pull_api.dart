import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_models.dart';

part 'tombstone_pull_api.g.dart';

/// Client du PULL KEYSET des retraits (`GET /sync/tombstones`, ADR-008/009).
///
/// [HttpResponse] pour exposer le statut : le `304 Not Modified` d'un cycle sans
/// retrait arrive comme une [DioException], et le `410 Gone` d'un curseur plus
/// ancien que la rétention du registre aussi. Jeton `cursor` opaque renvoyé
/// VERBATIM. Aucun paramètre d'année : une disparition n'a pas d'année scolaire,
/// et l'école est portée par le jeton.
@RestApi()
abstract class TombstonePullApi {
  factory TombstonePullApi(Dio dio, {String baseUrl}) = _TombstonePullApi;

  @GET(AppConstants.syncTombstonesEndpoint)
  Future<HttpResponse<TombstonePageDto>> pullTombstones(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
