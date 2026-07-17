import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Modèle de la table `payment_allocations` (append-only).
class PaymentAllocationLocalModel {
  final String id;
  final String clientUuid;
  final String paymentId;
  final String? studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const PaymentAllocationLocalModel({
    required this.id,
    required this.clientUuid,
    required this.paymentId,
    this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'client_uuid': clientUuid,
    'payment_id': paymentId,
    'student_charge_id': studentChargeId,
    'fee_code': feeCode,
    'student_charge_label': studentChargeLabel,
    'amount_in_cents': amountInCents,
    'currency': currency,
  };

  /// Même imputation, rattachée à une autre créance (re-résolution d'un uuid
  /// périmé au moment de l'écriture — cf.
  /// `FinancePaymentWriteDao._resolveChargeLink`).
  PaymentAllocationLocalModel withStudentChargeId(String? id) =>
      PaymentAllocationLocalModel(
        id: this.id,
        clientUuid: clientUuid,
        paymentId: paymentId,
        studentChargeId: id,
        feeCode: feeCode,
        studentChargeLabel: studentChargeLabel,
        amountInCents: amountInCents,
        currency: currency,
      );

  /// Colonnes dont le PULL est autoritaire (`openapi_billing_sync`
  /// §PaymentDelta.allocations : `id, studentChargeId?, feeCode,
  /// amountInCents`).
  ///
  /// **Exclut `student_charge_label` et `client_uuid`** : le contrat ne porte
  /// pas le libellé, le DTO le replie donc sur le `fee_code` — le réécrire
  /// remplacerait « Minerval Trimestre 1 » par « TUITION » sur le reçu
  /// réimprimé. Le libellé est FIGÉ au versement, il n'est jamais retiré.
  ///
  /// **`student_charge_id` n'est écrit que s'il est RÉSOLU** : le contrat le
  /// déclare `nullable` (créance pas encore matérialisée côté serveur). Un
  /// `null` du pull est une absence d'information, pas une rétractation — le
  /// propager effacerait le lien établi au versement ou par le remap de l'ACK.
  /// L'imputation disparaîtrait alors du détail du frais et, paiement encore
  /// pending, du `paid_pending` : le montant redeviendrait dû (FRONT §5).
  Map<String, Object?> toPullPatch() => {
    'payment_id': paymentId,
    if (studentChargeId != null) 'student_charge_id': studentChargeId,
    'fee_code': feeCode,
    'amount_in_cents': amountInCents,
    'currency': currency,
  };

  factory PaymentAllocationLocalModel.fromMap(Map<String, Object?> m) =>
      PaymentAllocationLocalModel(
        id: m['id'] as String,
        clientUuid: m['client_uuid'] as String,
        paymentId: m['payment_id'] as String,
        studentChargeId: m['student_charge_id'] as String?,
        feeCode: m['fee_code'] as String,
        studentChargeLabel: m['student_charge_label'] as String,
        amountInCents: (m['amount_in_cents'] as int?) ?? 0,
        currency: m['currency'] as String,
      );

  /// Le payeur et la date sont repliés depuis le paiement JOINT par l'appelant
  /// (ils ne sont pas des colonnes de `payment_allocations`) ; absents, l'entité
  /// les laisse vides / nuls.
  LocalPaymentAllocation toEntity({
    String payerFirstName = '',
    String payerLastName = '',
    String? payerMiddleName,
    String? paidAt,
  }) => LocalPaymentAllocation(
    id: id,
    paymentId: paymentId,
    studentChargeId: studentChargeId,
    feeCode: feeCode,
    studentChargeLabel: studentChargeLabel,
    amountInCents: amountInCents,
    currency: currency,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    paidAt: paidAt,
  );
}
