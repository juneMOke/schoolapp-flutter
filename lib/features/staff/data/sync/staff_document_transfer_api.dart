import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_push_dto.dart';

/// Les deux échanges binaires du fichier du personnel : verser une pièce
/// (multipart) et en relire les octets.
///
/// Écrits sur Dio et non sur Retrofit : la partie `metadata` doit partir en
/// `application/json`, ce que le générateur ne sait pas dire d'une partie.
class StaffDocumentTransferApi {
  final Dio _dio;

  const StaffDocumentTransferApi(this._dio);

  /// Verse [bytes] sous la partie `file`, décrits par [request].
  Future<StaffDocumentDeltaDto> upload(
    Map<String, dynamic> extras,
    StaffDocumentUploadDto request,
    Uint8List bytes,
  ) async {
    final form = FormData.fromMap({
      'metadata': MultipartFile.fromString(
        jsonEncode(request.toMetadata()),
        contentType: DioMediaType('application', 'json'),
      ),
      'file': MultipartFile.fromBytes(
        bytes,
        filename: request.fileName ?? request.id,
        contentType: DioMediaType.parse(request.mimeType),
      ),
    });
    final response = await _dio.post<Object?>(
      AppConstants.syncStaffDocumentsOfMemberEndpoint.replaceFirst(
        '{staffMemberId}',
        Uri.encodeComponent(request.staffMemberId),
      ),
      data: form,
      options: Options(extra: extras),
    );
    return StaffDocumentAck.parse(response.data);
  }

  /// Les octets de la pièce [documentId]. L'appelant les confronte à
  /// l'empreinte rangée : c'est elle qui fait foi, pas l'`ETag`.
  Future<Uint8List> download(
    Map<String, dynamic> extras,
    String documentId,
  ) async {
    final response = await _dio.get<List<int>>(
      AppConstants.staffDocumentContentEndpoint.replaceFirst(
        '{documentId}',
        Uri.encodeComponent(documentId),
      ),
      options: Options(extra: extras, responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }
}
