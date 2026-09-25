import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_delta_dto.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_error_codes.dart';

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

  final ExpenseDeltaDto? _canonical;

  const ExpensePushFailure._(
    this.status,
    this.detailCode,
    this.reason,
    this._canonical,
  );

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
    final body = e.response?.data;
    return ExpensePushFailure._(
      status,
      detailCode,
      reason,
      body is Map ? ExpenseDeltaDto.tryParse(body['expense']) : null,
    );
  }

  /// Statuts transitoires hormis les 5xx : jeton expiré (l'intercepteur
  /// ré-authentifie), délai, cadence.
  ///
  /// ⚠️ **Le 409 n'y est plus** : depuis le circuit, il porte deux sens aux
  /// conduites OPPOSÉES, que seul le `detailCode` sépare (F34). Le classer
  /// transitoire au vu du seul statut rejouerait une décision déjà prise par
  /// un collègue — c'est-à-dire l'écraserait.
  static const Set<int> transientStatuses = {401, 408, 429};

  /// Un 409 **sans** `detailCode` reste rejouable : c'est la course sur le
  /// même identifiant que le socle connaît depuis toujours. Avec un code, il
  /// faut le lire — [isRetriableConflict] et [isSettledElsewhere] le font.
  bool get isTransient =>
      status == null ||
      status! >= 500 ||
      transientStatuses.contains(status) ||
      (status == 409 && detailCode == null);

  /// 409 `TRANSITION_OUT_OF_ORDER` — le geste est arrivé avant son
  /// prédécesseur. **Rejouer, ne jamais réaligner** : la ligne locale est
  /// juste, c'est le serveur qui n'a pas encore vu ce qui vient avant.
  bool get isRetriableConflict =>
      status == 409 && detailCode == ExpenseErrorCodes.transitionOutOfOrder;

  /// 409 `DECISION_ALREADY_TAKEN` — un collègue a tranché avant nous.
  /// **Réaligner, ne jamais rejouer.**
  bool get isSettledElsewhere =>
      status == 409 && detailCode == ExpenseErrorCodes.decisionAlreadyTaken;

  /// L'état canonique que porte un 409 (Q8) : le poste réaligne statut ET fil
  /// d'un seul geste, et n'affiche jamais « approuvée par X » au-dessus d'un
  /// fil qui ne le dit pas.
  ExpenseDeltaDto? get canonical => _canonical;

  /// La dépense a été purgée physiquement côté serveur.
  bool get isTombstoned => status == 410;

  /// Code rangé sur la ligne : le `detailCode`, sinon le statut.
  String get storedCode =>
      detailCode ?? (status == null ? 'NETWORK' : 'HTTP_$status');
}
