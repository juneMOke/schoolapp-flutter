import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_push_response_models.dart';

/// Accusé de `POST /api/v1/sync/payment-corrections` (201, ou 200 au rejeu).
class PaymentCorrectionResponse {
  final String id;

  /// Le versement annulé.
  final String paymentId;

  /// ISO-8601 : l'annulation, telle que le serveur l'a posée.
  final String cancelledAt;

  /// Numéro du reçu annulé, `null` si l'origine n'en avait pas.
  final String? cancelledReceiptNumber;

  /// L'accusé du remplaçant, produit par le même assembleur que la réponse
  /// de `POST /sync/payments` (R8). `null` pour une annulation seule.
  final PaymentAggregateResponse? replacement;

  /// Les créances touchées, recalculées — des DEUX élèves quand le
  /// remplaçant a changé d'élève.
  final List<StudentChargeDto> charges;

  const PaymentCorrectionResponse({
    required this.id,
    required this.paymentId,
    required this.cancelledAt,
    this.cancelledReceiptNumber,
    this.replacement,
    this.charges = const [],
  });

  factory PaymentCorrectionResponse.fromJson(Map<String, dynamic> j) {
    final replacement = j['replacement'];
    return PaymentCorrectionResponse(
      id: j['id'] as String,
      paymentId: j['paymentId'] as String,
      cancelledAt: j['cancelledAt'] as String,
      cancelledReceiptNumber: j['cancelledReceiptNumber'] as String?,
      replacement: replacement is Map<String, dynamic>
          ? PaymentAggregateResponse.fromJson(replacement)
          : null,
      charges: (j['charges'] as List<dynamic>? ?? const [])
          .map((e) => StudentChargeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
