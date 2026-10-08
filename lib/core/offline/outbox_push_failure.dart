import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';

/// Lecture d'un échec d'envoi d'une entrée d'outbox.
///
/// Le transport, les 5xx et 401/408/409/429 se rejouent. Un 409 porteur d'un
/// code d'**attente** (le prérequis n'est pas encore arrivé au serveur) se lit
/// à part par [awaits], avant [isTransient]. Le 410 dit l'agrégat purgé. Tout
/// autre 4xx est déterministe : le serveur n'a rien écrit, et le rejouer
/// redonnerait le même refus.
class OutboxPushFailure {
  final int? status;
  final String? detailCode;

  /// Cause lisible : le code machine d'abord, la phrase du serveur ensuite.
  final String reason;

  const OutboxPushFailure(this.status, this.detailCode, this.reason);

  factory OutboxPushFailure.of(DioException e) => OutboxPushFailure(
    e.response?.statusCode,
    ApiErrorParser.detailCodeOf(e.response),
    ApiErrorParser.pushFailureReason(e),
  );

  static const Set<int> _transientStatuses = {401, 408, 409, 429};

  /// Un 409 qui dit d'attendre [code] : rejouer sans consommer de tentative.
  bool awaits(String code) => status == 409 && detailCode == code;

  /// L'agrégat a été purgé côté serveur : le geste n'a plus d'objet.
  bool get isGone => status == 410;

  bool get isTransient =>
      status == null || status! >= 500 || _transientStatuses.contains(status);

  /// Code rangé sur la ligne : le `detailCode`, sinon le statut.
  String get storedCode =>
      detailCode ?? (status == null ? 'NETWORK' : 'HTTP_$status');
}
