import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

/// La version déployée sur le serveur, telle que `version.json` la décrit
/// (`version+build_number`) ; `null` quand elle ne se lit pas (hors ligne,
/// fichier absent) — on ne conclut rien d'un échec.
abstract interface class DeployedBuildSource {
  Future<String?> read();
}

/// Lit `version.json` à côté de la page, sans cache : nginx le sert en
/// `no-cache`, mais un proxy intermédiaire n'est pas tenu de le respecter.
class HttpDeployedBuildSource implements DeployedBuildSource {
  final Dio _dio;
  final Uri _base;

  HttpDeployedBuildSource({required Dio dio, required Uri base})
    : _dio = dio,
      _base = base;

  @override
  Future<String?> read() async {
    try {
      final uri = _base
          .resolve(AppConstants.webVersionManifestPath)
          .replace(
            queryParameters: {
              't': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
      final response = await _dio.getUri<Map<String, dynamic>>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          headers: const {'Cache-Control': 'no-cache'},
        ),
      );
      return _buildOf(response.data);
    } on DioException {
      return null;
    }
  }

  static String? _buildOf(Map<String, dynamic>? manifest) {
    if (manifest == null) return null;
    final version = manifest['version'];
    final build = manifest['build_number'];
    if (version is! String) return null;
    return build == null ? version : '$version+$build';
  }
}
