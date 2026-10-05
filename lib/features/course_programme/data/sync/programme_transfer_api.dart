import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';

/// Les échanges binaires du programme : joindre une ressource (multipart,
/// fichier facultatif) et relire les octets d'un document.
///
/// Écrits sur Dio et non sur Retrofit : la partie `metadata` doit partir en
/// `application/json`, ce que le générateur ne sait pas dire d'une partie
/// (même raison que `StaffDocumentTransferApi`).
class ProgrammeTransferApi {
  final Dio _dio;

  const ProgrammeTransferApi(this._dio);

  static String _ressourcePath(String chapitreId, String ressourceId) =>
      AppConstants.syncAcademicsChapitreRessourceEndpoint
          .replaceFirst('{chapitreId}', Uri.encodeComponent(chapitreId))
          .replaceFirst('{ressourceId}', Uri.encodeComponent(ressourceId));

  /// Joint la ressource décrite par [payload] ; [bytes] seulement pour un
  /// document — un lien ou une référence de manuel part sans fichier.
  Future<void> putRessource(
    Map<String, dynamic> extras,
    ChapitreRessourcePayload payload, {
    Uint8List? bytes,
  }) async {
    final ressource = payload.ressource;
    final form = FormData.fromMap({
      'metadata': MultipartFile.fromString(
        jsonEncode(payload.toMetadata()),
        contentType: DioMediaType('application', 'json'),
      ),
      if (bytes != null)
        'file': MultipartFile.fromBytes(
          bytes,
          filename: ressource.fileName ?? ressource.id,
          contentType: ressource.mimeType == null
              ? null
              : DioMediaType.parse(ressource.mimeType!),
        ),
    });
    await _dio.put<Object?>(
      _ressourcePath(payload.chapitreId, ressource.id),
      data: form,
      options: Options(extra: extras),
    );
  }

  /// Les octets d'un document. L'appelant les confronte à l'empreinte rangée.
  Future<Uint8List> download(
    Map<String, dynamic> extras, {
    required String chapitreId,
    required String ressourceId,
  }) async {
    final response = await _dio.get<List<int>>(
      AppConstants.academicsChapitreRessourceContentEndpoint
          .replaceFirst('{chapitreId}', Uri.encodeComponent(chapitreId))
          .replaceFirst('{ressourceId}', Uri.encodeComponent(ressourceId)),
      options: Options(extra: extras, responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }
}
