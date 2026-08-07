// Réponse canonique du PUSH de l'agrégat paiement — miroir strict de
// `openapi_billing_sync.yaml` 1.1.0 §PaymentAggregateResponse
// (`POST /api/v1/sync/payments` → 201 création | 200 rejeu idempotent, mêmes
// valeurs canoniques).
//
// Le serveur ne rejette JAMAIS un paiement pour un motif métier (F3) : l'argent
// a été physiquement reçu au guichet. Un trop-perçu est ACCEPTÉ puis signalé via
// [OverpaymentSignal] pour arbitrage admin.

import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart'
    show StudentChargeDto;

/// Le paiement canonique renvoyé (spec `PaymentAggregateResponse.payment`) :
/// l'id honoré, et l'éventuel reçu scellé.
class AckPaymentRef {
  /// = l'uuid client envoyé (honoré).
  final String id;

  /// Reçu définitif serveur. `null` si le scellement a échoué (best-effort).
  final String? receiptId;

  const AckPaymentRef({required this.id, this.receiptId});

  factory AckPaymentRef.fromJson(Map<String, dynamic> j) => AckPaymentRef(
    id: j['id'] as String,
    receiptId: j['receiptId'] as String?,
  );
}

/// Remap d'une allocation : ids provisoires client → ids canoniques serveur
/// (spec `AllocationRemap`). Le [feeCode] est porté par la réponse — aucun
/// besoin de le relire en local pour résoudre la créance.
class AllocationRemap {
  /// uuid d'allocation envoyé par le client.
  final String providedId;
  final String canonicalId;

  /// Id de créance provisoire envoyé — diagnostic uniquement (le serveur
  /// l'ignore et remappe par `studentId + feeCode`).
  final String? providedStudentChargeId;

  /// Créance **autoritaire** après remap. **Nullable** : la spec ne la liste
  /// PAS dans `required` (seuls `providedId`, `canonicalId`, `feeCode` le
  /// sont) — le serveur peut ne pas avoir su lier l'allocation à une créance
  /// (ligne en trop-perçu, typiquement). Un remap sans cible est alors
  /// simplement **sauté**, comme le faisait l'ancien `AckAllocation`.
  ///
  /// La rendre requise poisonnerait tout le chemin : le cast lèverait dans la
  /// désérialisation, `PaymentOutboxHandler` retomberait en `retry`, l'ACK ne
  /// serait JAMAIS appliqué et le POST rejoué à chaque cycle — argent encaissé
  /// bloqué hors du grand-livre.
  final String? canonicalStudentChargeId;
  final String feeCode;

  const AllocationRemap({
    required this.providedId,
    required this.canonicalId,
    this.providedStudentChargeId,
    this.canonicalStudentChargeId,
    required this.feeCode,
  });

  factory AllocationRemap.fromJson(Map<String, dynamic> j) => AllocationRemap(
    providedId: j['providedId'] as String,
    canonicalId: j['canonicalId'] as String,
    providedStudentChargeId: j['providedStudentChargeId'] as String?,
    canonicalStudentChargeId: j['canonicalStudentChargeId'] as String?,
    feeCode: j['feeCode'] as String,
  );
}

/// Document scellé (RP / NP) — spec `GeneratedDocument`. Le [documentNumber]
/// définitif remplace le `PROV-…` émis localement.
class GeneratedDocumentDto {
  /// `PAYMENT_RECEIPT` (RC) | `PAYMENT_NOTICE` (NP).
  final String type;
  final String documentNumber;
  final String status; // DEFINITIVE
  final String? url;

  const GeneratedDocumentDto({
    required this.type,
    required this.documentNumber,
    required this.status,
    this.url,
  });

  factory GeneratedDocumentDto.fromJson(Map<String, dynamic> j) =>
      GeneratedDocumentDto(
        type: j['type'] as String,
        documentNumber: j['documentNumber'] as String,
        status: (j['status'] as String?) ?? 'DEFINITIVE',
        url: j['url'] as String?,
      );

  /// `doc_type` local de la table `generated_documents` (domaine `PAYMENT`).
  /// Un type inconnu est rendu tel quel : aucun `UPDATE` ne matchera, donc le
  /// reçu provisoire est conservé plutôt que corrompu.
  String get localDocType => switch (type) {
    'PAYMENT_RECEIPT' => 'RC',
    'PAYMENT_NOTICE' => 'NP',
    _ => type,
  };
}

/// Signal de trop-perçu — **jamais un rejet** (F3). Le paiement est enregistré
/// quoi qu'il arrive ; la réconciliation fine (avoirs/remboursements) est
/// différée V2.
class OverpaymentSignal {
  final bool detected;
  final int? excessInCents;
  final String? currency;
  final String? feeCode;
  final String? reason;

  const OverpaymentSignal({
    required this.detected,
    this.excessInCents,
    this.currency,
    this.feeCode,
    this.reason,
  });

  factory OverpaymentSignal.fromJson(Map<String, dynamic> j) =>
      OverpaymentSignal(
        detected: (j['detected'] as bool?) ?? false,
        excessInCents: (j['excessInCents'] as num?)?.toInt(),
        currency: j['currency'] as String?,
        feeCode: j['feeCode'] as String?,
        reason: j['reason'] as String?,
      );
}

/// ACK de l'agrégat paiement (spec `PaymentAggregateResponse`).
class PaymentAggregateResponse {
  final AckPaymentRef payment;

  /// Remap des ids provisoires → canoniques.
  final List<AllocationRemap> allocations;

  /// Créances **recalculées, autoritaires** après imputation — même schéma que
  /// le pull (`StudentCharge`) : le client remplace son snapshot optimiste par
  /// ces valeurs (ADR-002).
  final List<StudentChargeDto> charges;

  /// Documents scellés. **Peut être vide** : le scellement est hors transaction
  /// d'ingestion (best-effort, décision G). Un échec de rendu laisse le paiement
  /// enregistré — l'absence de document n'est JAMAIS un échec d'encaissement.
  final List<GeneratedDocumentDto> documents;

  final OverpaymentSignal? overpayment;

  const PaymentAggregateResponse({
    required this.payment,
    this.allocations = const [],
    this.charges = const [],
    this.documents = const [],
    this.overpayment,
  });

  /// Id du paiement acquitté (= uuid client honoré).
  String get paymentId => payment.id;

  /// UUID de la pièce scellée, seule clé de re-téléchargement du reçu définitif
  /// (`GET /editique/documents/{id}`). `null` est un cas NORMAL : le scellement
  /// serveur est best-effort et hors transaction.
  String? get receiptId => payment.receiptId;

  factory PaymentAggregateResponse.fromJson(
    Map<String, dynamic> j,
  ) => PaymentAggregateResponse(
    payment: AckPaymentRef.fromJson(j['payment'] as Map<String, dynamic>),
    allocations: (j['allocations'] as List<dynamic>? ?? const [])
        .map((e) => AllocationRemap.fromJson(e as Map<String, dynamic>))
        .toList(),
    charges: (j['charges'] as List<dynamic>? ?? const [])
        .map((e) => StudentChargeDto.fromJson(e as Map<String, dynamic>))
        .toList(),
    documents: (j['documents'] as List<dynamic>? ?? const [])
        .map((e) => GeneratedDocumentDto.fromJson(e as Map<String, dynamic>))
        .toList(),
    overpayment: j['overpayment'] == null
        ? null
        : OverpaymentSignal.fromJson(j['overpayment'] as Map<String, dynamic>),
  );
}
