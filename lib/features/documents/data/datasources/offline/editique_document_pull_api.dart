import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/documents/data/models/editique_document_pull_models.dart';

part 'editique_document_pull_api.g.dart';

/// Client du PULL KEYSET de l'éditique — miroir *lecture* de
/// `GET /api/v1/sync/editique-documents` (ADR-008/009, lot back B3).
///
/// [HttpResponse] pour exposer le statut : le `304` d'un cycle sans nouveauté
/// arrive comme une [DioException] de statut 304, sans corps — idiome du socle.
///
/// **Aucun paramètre de cadrage.** Les sept autres flux prennent une année ;
/// celui-ci n'en prend pas, parce que l'année est nullable sur les pièces
/// scellées : la demander laisserait ces lignes hors de portée pour toujours.
/// Le cadrage est l'école, et il vient du jeton.
@RestApi()
abstract class EditiqueDocumentPullApi {
  factory EditiqueDocumentPullApi(Dio dio, {String baseUrl}) =
      _EditiqueDocumentPullApi;

  /// Métadonnées des pièces scellées de l'école. Jeton `cursor` **opaque**,
  /// renvoyé VERBATIM ; `limit` borné [1, 500] côté serveur (défaut 100).
  @GET(AppConstants.syncEditiqueDocumentsEndpoint)
  Future<HttpResponse<EditiqueDocumentPageDto>> pullEditiqueDocuments(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );
}
