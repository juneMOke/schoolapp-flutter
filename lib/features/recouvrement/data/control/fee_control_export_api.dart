import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/recouvrement/data/export_bytes_guard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';

/// L'export du contrôle des frais (R11) : `POST /finance/relance-list` au
/// **format v2** (`filter`). La tablette envoie ses lignes — le contrôle est
/// lu sur l'appareil, encaissements pas encore remontés compris —, le serveur
/// vérifie que chacune répond au filtre et imprime : PDF `ER` numéroté, ou
/// classeur non numéroté.
class FeeControlExportApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const FeeControlExportApi(this._dio, this._extras);

  Future<RecoveryExportFile> export(
    Map<String, dynamic> body,
    RecoveryExportFormat format,
  ) async {
    final pdf = format == RecoveryExportFormat.pdf;
    final response = await _dio.post<List<int>>(
      AppConstants.recouvrementRelanceListEndpoint,
      queryParameters: {'format': format.name},
      data: body,
      options: Options(
        extra: _extras,
        responseType: ResponseType.bytes,
        // Le serveur rend en mémoire avant d'émettre (1 à 7 s) ; la montée,
        // elle, se borne sur le lien.
        receiveTimeout: AppConstants.recouvrementRelanceListTimeout,
        sendTimeout: AppConstants.recouvrementRelanceListSendTimeout,
        headers: <String, String>{
          'Accept': pdf
              ? AppConstants.pdfAcceptHeader
              : AppConstants.xlsxAcceptHeader,
          Headers.contentEncodingHeader: 'gzip',
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
        requestEncoder: _gzipJson,
      ),
    );
    final bytes = Uint8List.fromList(response.data ?? const []);
    ExportBytesGuard.check(
      bytes,
      response.headers.value(Headers.contentTypeHeader),
      format,
    );
    return RecoveryExportFile(
      format: format,
      bytes: bytes,
      fileName:
          ContentDispositionParser.fileName(
            response.headers.value('content-disposition'),
          ) ??
          'controle.${format.name}',
    );
  }

  /// Le corps monte à 1,6 Mio décompressé au plafond ; gzippé, sous 300 Ko.
  static List<int> _gzipJson(String request, RequestOptions options) =>
      const GZipEncoder().encodeBytes(utf8.encode(request));
}
