// Contrat Dart de l'agrégat paiement (FF-Lot 4). `POST /api/v1/finance/payments`
// enrichi : `id` client honoré (idempotence money-grade), `paidAt` ISO honoré,
// `method`, jamais rejeté métier. Centimes `int`, 23 `feeCode`.

// ── Requête ──────────────────────────────────────────────────────────────────

class PaymentAllocationRequest {
  final String id; // uuid client honoré (idempotence fine de l'allocation)
  final String? studentChargeId; // réel | provisoire | null (avance)
  final String feeCode; // clé de remap serveur (23 valeurs)
  final String studentChargeLabel; // libellé figé au versement
  final int amountInCents;
  final String currency;

  const PaymentAllocationRequest({
    required this.id,
    this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'clientUuid': id,
    'studentChargeId': studentChargeId,
    'feeCode': feeCode,
    'studentChargeLabel': studentChargeLabel,
    'amountInCents': amountInCents,
    'currency': currency,
  };

  factory PaymentAllocationRequest.fromJson(Map<String, dynamic> j) =>
      PaymentAllocationRequest(
        id: j['id'] as String,
        studentChargeId: j['studentChargeId'] as String?,
        feeCode: j['feeCode'] as String,
        studentChargeLabel: (j['studentChargeLabel'] as String?) ?? '',
        amountInCents: (j['amountInCents'] as num).toInt(),
        currency: j['currency'] as String,
      );
}

class CreatePaymentRequest {
  final String id; // uuid CLIENT = id serveur honoré
  final String studentId;
  final String academicYearId;
  final int amountInCents; // total == Σ allocations
  final String currency;
  final String? method; // défaut CASH
  final String paidAt; // ISO-8601 — date terrain
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final List<PaymentAllocationRequest> allocations;

  const CreatePaymentRequest({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    this.method,
    required this.paidAt,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    required this.allocations,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'clientUuid': id, // enrichissement idempotence money-grade
    'studentId': studentId,
    'academicYearId': academicYearId,
    'amountInCents': amountInCents,
    'currency': currency,
    'method': method ?? 'CASH',
    'paidAt': paidAt,
    'payerFirstName': payerFirstName,
    'payerLastName': payerLastName,
    'payerMiddleName': payerMiddleName,
    'allocations': allocations.map((a) => a.toJson()).toList(),
  };

  factory CreatePaymentRequest.fromJson(Map<String, dynamic> j) =>
      CreatePaymentRequest(
        id: j['id'] as String,
        studentId: j['studentId'] as String,
        academicYearId: j['academicYearId'] as String,
        amountInCents: (j['amountInCents'] as num).toInt(),
        currency: j['currency'] as String,
        method: j['method'] as String?,
        paidAt: j['paidAt'] as String,
        payerFirstName: j['payerFirstName'] as String,
        payerLastName: j['payerLastName'] as String,
        payerMiddleName: j['payerMiddleName'] as String?,
        allocations: (j['allocations'] as List<dynamic>? ?? const [])
            .map(
              (e) =>
                  PaymentAllocationRequest.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
}

// ── Réponse (ACK) ────────────────────────────────────────────────────────────

class AckPayment {
  final String id; // = id client honoré
  final String? status;
  final String? paidAt; // date retenue serveur

  const AckPayment({required this.id, this.status, this.paidAt});

  factory AckPayment.fromJson(Map<String, dynamic> j) => AckPayment(
    id: j['id'] as String,
    status: j['status'] as String?,
    paidAt: j['paidAt'] as String?,
  );
}

class AckAllocation {
  final String id; // = id client (aucun remap d'id)
  final String? studentChargeId; // provisoire → réel (remap serveur)

  const AckAllocation({required this.id, this.studentChargeId});

  factory AckAllocation.fromJson(Map<String, dynamic> j) => AckAllocation(
    id: j['id'] as String,
    studentChargeId: j['studentChargeId'] as String?,
  );
}

/// Solde AUTORITAIRE recalculé par le serveur (écrase le local à l'ACK).
class AckCharge {
  final String id;
  final int amountPaidInCents;
  final String status; // DUE|PARTIAL|PAID

  const AckCharge({
    required this.id,
    required this.amountPaidInCents,
    required this.status,
  });

  factory AckCharge.fromJson(Map<String, dynamic> j) => AckCharge(
    id: j['id'] as String,
    amountPaidInCents: (j['amountPaidInCents'] as num?)?.toInt() ?? 0,
    status: (j['status'] as String?) ?? 'DUE',
  );
}

/// Signal de trop-perçu (crédit) — informatif, jamais bloquant.
class OverpaymentSignal {
  final int amountInCents;
  final String? currency;

  const OverpaymentSignal({required this.amountInCents, this.currency});

  factory OverpaymentSignal.fromJson(Map<String, dynamic> j) =>
      OverpaymentSignal(
        amountInCents: (j['amountInCents'] as num?)?.toInt() ?? 0,
        currency: j['currency'] as String?,
      );
}

/// ACK d'un paiement, corrélé par [paymentId] (= payment.id client honoré).
class PaymentCommitAck {
  final String paymentId;
  final AckPayment payment;
  final List<AckAllocation> allocations;
  final List<AckCharge> updatedCharges;
  final OverpaymentSignal? overpayment;

  const PaymentCommitAck({
    required this.paymentId,
    required this.payment,
    this.allocations = const [],
    this.updatedCharges = const [],
    this.overpayment,
  });

  factory PaymentCommitAck.fromJson(Map<String, dynamic> j) => PaymentCommitAck(
    paymentId: (j['paymentId'] ?? (j['payment'] as Map?)?['id']) as String,
    payment: AckPayment.fromJson(j['payment'] as Map<String, dynamic>),
    allocations: (j['allocations'] as List<dynamic>? ?? const [])
        .map((e) => AckAllocation.fromJson(e as Map<String, dynamic>))
        .toList(),
    updatedCharges: (j['updatedCharges'] as List<dynamic>? ?? const [])
        .map((e) => AckCharge.fromJson(e as Map<String, dynamic>))
        .toList(),
    overpayment: j['overpayment'] == null
        ? null
        : OverpaymentSignal.fromJson(j['overpayment'] as Map<String, dynamic>),
  );
}
