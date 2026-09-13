import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';

/// Lecture d'un échec de remontée, partagée par les deux handlers.
///
/// Même partage que la caisse (`payment_outbox_handler._classifyDioError`) :
/// le transport, les 5xx et 401/408/409/429 se rejouent ; tout autre 4xx est
/// déterministe — la remontée est idempotente, un 4xx dit que le serveur n'a
/// **rien** écrit, et le rejouer jusqu'au poison ne ferait que retarder le
/// même refus.
class ExpensePushFailure {
  final int? status;

  /// Code machine du refus (`detailCode`), ou `null`.
  final String? detailCode;

  /// Cause lisible : le code machine d'abord, la phrase du serveur ensuite.
  final String reason;

  const ExpensePushFailure._(this.status, this.detailCode, this.reason);

  factory ExpensePushFailure.of(DioException e) {
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
    return ExpensePushFailure._(status, detailCode, reason);
  }

  /// Statuts transitoires hormis les 5xx : jeton expiré (l'intercepteur
  /// ré-authentifie), délai, course sur le même identifiant (409, « rejouez »),
  /// cadence.
  static const Set<int> transientStatuses = {401, 408, 409, 429};

  bool get isTransient =>
      status == null || status! >= 500 || transientStatuses.contains(status);

  /// La dépense a été purgée physiquement côté serveur.
  bool get isTombstoned => status == 410;

  /// Code rangé sur la ligne : le `detailCode`, sinon le statut.
  String get storedCode =>
      detailCode ?? (status == null ? 'NETWORK' : 'HTTP_$status');
}
