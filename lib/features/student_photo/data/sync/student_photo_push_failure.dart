import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';

/// Lecture d'un échec d'envoi d'un geste sur une photo.
///
/// Le transport, les 5xx et 401/408/409/429 se rejouent. Deux réponses ont
/// leur conduite propre : le 409 `STUDENT_NOT_YET_SYNCED` est une **attente**
/// (l'inscription qui crée l'élève n'est pas arrivée — rejouer sans consommer
/// de tentative), le 410 `AGGREGATE_TOMBSTONED` dit l'élève purgé (le geste
/// s'efface). Tout autre 4xx — 400, 403 sans le droit, 404 élève d'une autre
/// école, 415, 422 `PHOTO_NOT_SQUARE` / `PHOTO_TOO_LARGE`… — est
/// déterministe : le serveur n'a rien écrit, et le rejouer redonnerait le même
/// refus.
class StudentPhotoPushFailure {
  final int? status;
  final String? detailCode;

  /// Cause lisible : le code machine d'abord, la phrase du serveur ensuite.
  final String reason;

  const StudentPhotoPushFailure._(this.status, this.detailCode, this.reason);

  static const String studentNotYetSynced = 'STUDENT_NOT_YET_SYNCED';

  factory StudentPhotoPushFailure.of(DioException e) {
    final status = e.response?.statusCode;
    final detailCode = ApiErrorParser.detailCodeOf(e.response);
    final serverMessage = ApiErrorParser.serverMessageOf(e.response);
    final String reason;
    if (detailCode != null) {
      reason = serverMessage == null
          ? detailCode
          : '$detailCode — $serverMessage';
    } else {
      final where = status != null ? 'HTTP $status' : 'réseau';
      final detail = serverMessage ?? e.message ?? e.error?.toString();
      reason = detail == null || detail.isEmpty ? where : '$where — $detail';
    }
    return StudentPhotoPushFailure._(status, detailCode, reason);
  }

  static const Set<int> _transientStatuses = {401, 408, 409, 429};

  /// Le serveur n'a pas encore l'élève : son inscription est en route.
  bool get awaitsStudent => status == 409 && detailCode == studentNotYetSynced;

  /// L'élève a été purgé côté serveur : le geste n'a plus d'objet.
  bool get isStudentGone => status == 410;

  bool get isTransient =>
      !awaitsStudent &&
      (status == null || status! >= 500 || _transientStatuses.contains(status));

  /// Code rangé sur la ligne : le `detailCode`, sinon le statut.
  String get storedCode =>
      detailCode ?? (status == null ? 'NETWORK' : 'HTTP_$status');
}
