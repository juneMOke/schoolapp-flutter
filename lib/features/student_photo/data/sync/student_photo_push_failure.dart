import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';

/// Lecture d'un échec d'envoi d'un geste sur une photo.
///
/// Le transport, les 5xx et 401/408/429 se rejouent. Le 404
/// `STUDENT_NOT_FOUND` dit que le serveur ne connaît pas (encore) l'élève :
/// c'est l'appelant qui sait si l'inscription est en route. Tout autre 4xx
/// (403 sans le droit, 413, 415, 422 `PHOTO_NOT_SQUARE` / `PHOTO_TOO_LARGE`)
/// est déterministe : le serveur n'a rien écrit, et le rejouer redonnerait le
/// même refus.
class StudentPhotoPushFailure {
  final int? status;
  final String? detailCode;

  /// Cause lisible : le code machine d'abord, la phrase du serveur ensuite.
  final String reason;

  const StudentPhotoPushFailure._(this.status, this.detailCode, this.reason);

  static const String studentNotFound = 'STUDENT_NOT_FOUND';

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

  bool get isTransient =>
      status == null || status! >= 500 || _transientStatuses.contains(status);

  /// Le serveur ne connaît pas l'élève. Un 404 sans code se lit de même : la
  /// route n'a pas d'autre ressource à ne pas trouver.
  bool get isStudentUnknown =>
      status == 404 && (detailCode == null || detailCode == studentNotFound);

  /// Code rangé sur la ligne : le `detailCode`, sinon le statut.
  String get storedCode =>
      detailCode ?? (status == null ? 'NETWORK' : 'HTTP_$status');
}
