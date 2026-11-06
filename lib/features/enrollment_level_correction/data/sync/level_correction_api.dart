import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';

/// L'envoi d'une correction de niveau : un geste par requête.
///
/// Le corps rendu (inscription, créances, créances supprimées, membre de
/// classe) n'est pas encore lu : ses noms de champs ne sont pas figés au
/// contrat. La tablette se recale par la descente que le handler déclenche
/// après l'accusé.
class LevelCorrectionApi {
  final Dio _dio;

  const LevelCorrectionApi(this._dio);

  /// Envoie [gesture]. 201 (appliqué) et 200 (rejeu) se valent : dans les deux
  /// cas le geste est au serveur. Tout autre statut remonte en `DioException`.
  Future<void> push(
    Map<String, dynamic> extras,
    LevelCorrectionGesture gesture,
  ) async {
    await _dio.post<Object?>(
      AppConstants.syncEnrollmentLevelCorrectionsEndpoint,
      data: gesture.toWire(),
      options: Options(extra: extras),
    );
  }
}
