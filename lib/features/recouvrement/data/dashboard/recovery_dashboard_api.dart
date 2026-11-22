import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';

/// Une réponse JSON brute et l'heure du serveur — le cache la garde telle quelle.
typedef RecoveryJson = Map<String, dynamic>;

/// Les quatre routes du tableau de bord du Recouvrement v2, sur Dio — toutes en
/// **lecture** : rien ne s'écrit, rien ne passe par l'outbox.
class RecoveryDashboardApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const RecoveryDashboardApi(this._dio, this._extras);

  Future<RecoveryJson> dashboard(Map<String, dynamic> query) =>
      _json(AppConstants.recoveryDashboardEndpoint, query);

  Future<RecoveryJson> students(Map<String, dynamic> query) =>
      _json(AppConstants.recoveryStudentsEndpoint, query);

  /// Le PDF ou le classeur. ⚠️ Chaque PDF **consomme un numéro de pièce** :
  /// l'appelant garde les octets plutôt que de redemander.
  Future<RecoveryExportFile> export(
    Map<String, dynamic> query,
    RecoveryExportFormat format,
  ) async {
    final pdf = format == RecoveryExportFormat.pdf;
    final response = await _dio.get<List<int>>(
      pdf
          ? AppConstants.recoveryStudentsPdfEndpoint
          : AppConstants.recoveryStudentsXlsxEndpoint,
      queryParameters: query,
      options: Options(
        extra: _extras,
        responseType: ResponseType.bytes,
        headers: {
          'Accept': pdf
              ? AppConstants.pdfAcceptHeader
              : AppConstants.xlsxAcceptHeader,
        },
        // Le serveur rend en mémoire avant d'émettre : même budget que la
        // liste de relance, pas les 12 s du JSON de guichet.
        receiveTimeout: AppConstants.recouvrementRelanceListTimeout,
      ),
    );
    final bytes = Uint8List.fromList(response.data ?? const []);
    if (bytes.isEmpty) {
      throw const FormatException('Le document reçu est vide.');
    }
    final situationAt = DateTime.tryParse(
      response.headers.value('x-situation-at') ?? '',
    )?.toLocal();
    return RecoveryExportFile(
      format: format,
      bytes: bytes,
      fileName:
          ContentDispositionParser.fileName(
            response.headers.value('content-disposition'),
          ) ??
          'recouvrement.${format.name}',
      situationAt: situationAt,
    );
  }

  Future<RecoveryJson> _json(String path, Map<String, dynamic> query) async {
    final response = await _dio.get<Object?>(
      path,
      queryParameters: query,
      options: Options(extra: _extras),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    throw const FormatException('Réponse du recouvrement illisible.');
  }
}
