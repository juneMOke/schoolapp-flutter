import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Modèle de la table `payments`.
class PaymentLocalModel {
  final String id;
  final String clientUuid;
  final String studentId;
  final String? academicYearId;
  final int amountInCents;
  final String currency;
  final String method;
  final String paidAt;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final String? status;
  final String syncStatus;
  final String? syncError;
  final int? syncedAt;
  final int updatedAt;

  const PaymentLocalModel({
    required this.id,
    required this.clientUuid,
    required this.studentId,
    this.academicYearId,
    required this.amountInCents,
    required this.currency,
    this.method = 'CASH',
    required this.paidAt,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.status,
    this.syncStatus = 'PENDING_SYNC',
    this.syncError,
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'client_uuid': clientUuid,
    'student_id': studentId,
    'academic_year_id': academicYearId,
    'amount_in_cents': amountInCents,
    'currency': currency,
    'method': method,
    'paid_at': paidAt,
    'payer_first_name': payerFirstName,
    'payer_last_name': payerLastName,
    'payer_middle_name': payerMiddleName,
    'status': status,
    'sync_status': syncStatus,
    'sync_error': syncError,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  /// Colonnes dont le PULL est autoritaire (`openapi_billing_sync`
  /// §PaymentDelta). Sert au patch d'une ligne DÉJÀ connue ; une ligne inconnue
  /// (paiement de l'autre poste) s'insère via [toMap].
  ///
  /// **Exclut l'identité du payeur et `client_uuid`** : le contrat ne les porte
  /// pas. Les réécrire depuis un DTO de pull les remplacerait par le repli `''`
  /// — perte définitive du nom saisi au guichet.
  ///
  /// **Exclut surtout l'état de synchro** (`sync_status`, `sync_error`,
  /// `synced_at`) : il appartient à l'ACK et à l'outbox, JAMAIS au pull. Le pull
  /// dit « le serveur connaît ce paiement », pas « ton miroir de créances a
  /// intégré son montant » — or c'est ce second fait que `sync_status` encode
  /// pour la lecture composée. Le passer à SYNCED ici sortirait le paiement du
  /// `paid_pending` (FRONT §5) alors que `student_charges.amount_paid` peut
  /// encore être périmé : la créance s'afficherait IMPAYÉE et le caissier
  /// **réencaisserait**. Seul `applyPaymentAck` bascule SYNCED — et il le fait
  /// dans la MÊME transaction que l'intégration des créances autoritaires.
  /// **Exclut `status` et `method`** : `PaymentDelta` ne porte pas `status` du
  /// tout (le DTO le laisse donc toujours `null` → le patch viderait la colonne
  /// locale), et `method` y est `nullable` alors que `PaymentDto.toLocalModel`
  /// replie sur `'CASH'` — patcher écraserait un `BANK_TRANSFER` saisi au
  /// guichet par un `CASH` inventé. Ces deux colonnes restent celles du poste
  /// qui a encaissé.
  Map<String, Object?> toPullPatch() => {
    'student_id': studentId,
    'academic_year_id': academicYearId,
    'amount_in_cents': amountInCents,
    'currency': currency,
    'paid_at': paidAt,
    'updated_at': updatedAt,
  };

  factory PaymentLocalModel.fromMap(Map<String, Object?> m) =>
      PaymentLocalModel(
        id: m['id'] as String,
        clientUuid: m['client_uuid'] as String,
        studentId: m['student_id'] as String,
        academicYearId: m['academic_year_id'] as String?,
        amountInCents: (m['amount_in_cents'] as int?) ?? 0,
        currency: m['currency'] as String,
        method: (m['method'] as String?) ?? 'CASH',
        paidAt: m['paid_at'] as String,
        payerFirstName: m['payer_first_name'] as String,
        payerLastName: m['payer_last_name'] as String,
        payerMiddleName: m['payer_middle_name'] as String?,
        status: m['status'] as String?,
        syncStatus: (m['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncError: m['sync_error'] as String?,
        syncedAt: m['synced_at'] as int?,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  LocalPayment toEntity() => LocalPayment(
    id: id,
    clientUuid: clientUuid,
    studentId: studentId,
    academicYearId: academicYearId,
    amountInCents: amountInCents,
    currency: currency,
    method: PaymentMethod.fromApiValue(method),
    paidAt: paidAt,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    status: status,
    syncState: SyncState.fromDbValue(syncStatus),
  );
}
