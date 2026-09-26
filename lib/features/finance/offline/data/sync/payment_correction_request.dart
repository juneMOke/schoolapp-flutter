import 'package:school_app_flutter/features/finance/offline/data/sync/payment_push_request_models.dart';

/// Corps de `POST /api/v1/sync/payment-corrections`, tel que l'outbox le
/// garde (agrégat `PAYMENT_CORRECTION`).
///
/// [id] est la clé d'idempotence : un rejeu avec le même id rend 200 et
/// l'état déjà appliqué.
class PaymentCorrectionRequest {
  final String id;

  /// Le versement visé.
  final String paymentId;

  final String reasonCode;

  /// Précision libre, requise par le serveur pour `OTHER`.
  final String? reason;

  final bool cashMoved;

  /// ISO-8601 UTC, l'heure du geste. Le serveur la borne à son horloge.
  final String clientCancelledAt;

  /// Uid de l'auteur, figé à la saisie (même garde que le push des
  /// versements).
  final String? authorId;

  /// Le remplaçant, dans la MÊME forme que `POST /sync/payments` —
  /// `authorId` en moins, porté une fois au niveau de la correction. `null`
  /// pour une annulation seule.
  final PaymentAggregateRequest? replacement;

  const PaymentCorrectionRequest({
    required this.id,
    required this.paymentId,
    required this.reasonCode,
    required this.clientCancelledAt,
    this.reason,
    this.cashMoved = false,
    this.authorId,
    this.replacement,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'paymentId': paymentId,
    'reasonCode': reasonCode,
    if (reason != null) 'reason': reason,
    'cashMoved': cashMoved,
    'clientCancelledAt': clientCancelledAt,
    if (authorId != null) 'authorId': authorId,
    if (replacement != null)
      'replacement': {
        'payment': replacement!.payment.toJson(),
        'allocations': replacement!.allocations.map((a) => a.toJson()).toList(),
      },
  };

  factory PaymentCorrectionRequest.fromJson(Map<String, dynamic> j) {
    final replacement = j['replacement'];
    return PaymentCorrectionRequest(
      id: j['id'] as String,
      paymentId: j['paymentId'] as String,
      reasonCode: j['reasonCode'] as String,
      reason: j['reason'] as String?,
      cashMoved: (j['cashMoved'] as bool?) ?? false,
      clientCancelledAt: j['clientCancelledAt'] as String,
      authorId: j['authorId'] as String?,
      replacement: replacement is Map<String, dynamic>
          ? PaymentAggregateRequest.fromJson(replacement)
          : null,
    );
  }
}
