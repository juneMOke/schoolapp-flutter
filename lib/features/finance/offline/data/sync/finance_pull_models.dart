// DTOs de pull delta (FF-Lot 2). Grille tarifaire + grand-livre autoritaire.
// Réponses serveur (fromJson) → converties en modèles locaux au upsert.

import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';

/// Mappe une liste serveur en **tolérant les lignes malformées** : une ligne
/// dont le `fromJson` lève est ignorée au lieu de faire échouer toute la page.
///
/// Money-grade — sans ça, un seul enregistrement fautif (champ requis à `null`,
/// montant absent) fige le curseur de la ressource : le cycle re-tire la même
/// page indéfiniment et le miroir local reste gelé, invisible pour le caissier.
/// La ligne écartée réapparaîtra au prochain delta une fois le serveur corrigé.
/// (Pour un paiement, l'échec d'une allocation nested écarte le paiement ENTIER
/// via ce même filet au niveau de la page — jamais une application partielle.)
List<T> _lenientList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(e as Map<String, dynamic>));
    } catch (_) {
      // Ligne écartée : le curseur avance, la ressource ne fige pas.
    }
  }
  return out;
}

class FeeTariffDto {
  final String id;
  final String? academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String feeCode;
  final String label;
  final int amountInCents;
  final String currency;
  final String? dueAt;
  final int version;

  const FeeTariffDto({
    required this.id,
    this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    this.dueAt,
    this.version = 0,
  });

  factory FeeTariffDto.fromJson(Map<String, dynamic> j) => FeeTariffDto(
    id: j['id'] as String,
    academicYearId: j['academicYearId'] as String?,
    schoolLevelId: j['schoolLevelId'] as String?,
    schoolLevelGroupId: j['schoolLevelGroupId'] as String?,
    feeCode: j['feeCode'] as String,
    label: j['label'] as String,
    amountInCents: (j['amountInCents'] as num).toInt(),
    currency: j['currency'] as String,
    dueAt: j['dueAt'] as String?,
    version: (j['version'] as num?)?.toInt() ?? 0,
  );

  FeeTariffLocalModel toLocalModel(int now) => FeeTariffLocalModel(
    id: id,
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    feeCode: feeCode,
    label: label,
    amountInCents: amountInCents,
    currency: currency,
    dueAt: dueAt,
    version: version,
    syncedAt: now,
    updatedAt: now,
  );
}

class StudentChargeDto {
  final String id;
  final String studentId;
  final String? academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String? feeTariffId;
  final String feeCode;
  final String label;
  final int expectedAmountInCents;
  final int amountPaidInCents; // autoritaire
  final String currency;
  final String status;
  final String? dueAt;
  final int version;

  const StudentChargeDto({
    required this.id,
    required this.studentId,
    this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    this.feeTariffId,
    required this.feeCode,
    required this.label,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    required this.currency,
    required this.status,
    this.dueAt,
    this.version = 0,
  });

  factory StudentChargeDto.fromJson(Map<String, dynamic> j) => StudentChargeDto(
    id: j['id'] as String,
    studentId: j['studentId'] as String,
    academicYearId: j['academicYearId'] as String?,
    schoolLevelId: j['schoolLevelId'] as String?,
    schoolLevelGroupId: j['schoolLevelGroupId'] as String?,
    feeTariffId: j['feeTariffId'] as String?,
    feeCode: j['feeCode'] as String,
    label: j['label'] as String,
    expectedAmountInCents: (j['expectedAmountInCents'] as num).toInt(),
    amountPaidInCents: (j['amountPaidInCents'] as num?)?.toInt() ?? 0,
    currency: j['currency'] as String,
    status: (j['status'] as String?) ?? 'DUE',
    dueAt: j['dueAt'] as String?,
    version: (j['version'] as num?)?.toInt() ?? 0,
  );

  /// Autoritaire : `amount_paid` ET `optimistic_paid` alignés sur le serveur.
  StudentChargeLocalModel toLocalModel(int now) => StudentChargeLocalModel(
    id: id,
    studentId: studentId,
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    feeTariffId: feeTariffId,
    feeCode: feeCode,
    label: label,
    expectedAmountInCents: expectedAmountInCents,
    amountPaidInCents: amountPaidInCents,
    optimisticPaidInCents: amountPaidInCents,
    currency: currency,
    // Le contrat de pull émet UNPAID ; le local (créances offline) émet DUE —
    // sémantiquement identiques (rien payé). On normalise pour ne pas mélanger
    // les deux vocabulaires dans la colonne `status`.
    status: status == 'UNPAID' ? 'DUE' : status,
    dueAt: dueAt,
    version: version,
    syncStatus: 'SYNCED',
    syncedAt: now,
    updatedAt: now,
  );
}

class PaymentDto {
  final String id;
  final String studentId;
  final String? academicYearId;
  final int amountInCents;
  final String currency;
  final String? method;
  final String paidAt;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final String? status;

  const PaymentDto({
    required this.id,
    required this.studentId,
    this.academicYearId,
    required this.amountInCents,
    required this.currency,
    this.method,
    required this.paidAt,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    this.status,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> j) => PaymentDto(
    id: j['id'] as String,
    studentId: j['studentId'] as String,
    academicYearId: j['academicYearId'] as String?,
    amountInCents: (j['amountInCents'] as num).toInt(),
    currency: j['currency'] as String,
    method: j['method'] as String?,
    paidAt: j['paidAt'] as String,
    payerFirstName: (j['payerFirstName'] as String?) ?? '',
    payerLastName: (j['payerLastName'] as String?) ?? '',
    payerMiddleName: j['payerMiddleName'] as String?,
    status: j['status'] as String?,
  );

  PaymentLocalModel toLocalModel(int now) => PaymentLocalModel(
    id: id,
    clientUuid: id,
    studentId: studentId,
    academicYearId: academicYearId,
    amountInCents: amountInCents,
    currency: currency,
    method: method ?? 'CASH',
    paidAt: paidAt,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    status: status,
    syncStatus: 'SYNCED',
    syncedAt: now,
    updatedAt: now,
  );
}

/// Delta de grille tarifaire.
class FeeTariffDelta {
  final List<FeeTariffDto> tariffs;
  final int? serverCursor;

  const FeeTariffDelta({this.tariffs = const [], this.serverCursor});

  factory FeeTariffDelta.fromJson(Map<String, dynamic> j) => FeeTariffDelta(
    tariffs: _lenientList(j['tariffs'], FeeTariffDto.fromJson),
    serverCursor: (j['serverCursor'] as num?)?.toInt(),
  );
}

// ── Pull KEYSET (contrat openapi_billing_sync, ADR-008/009) ──────────────────
// Enveloppe de pagination opaque partagée avec l'Inscription (KeysetPageEnvelope
// / KeysetPageDto) : `nextCursor`/`nextWatermark` base64url renvoyés VERBATIM
// sur l'unique paramètre `cursor`, jamais décodés ni recalculés.

/// Page keyset des créances élèves (`GET /api/v1/sync/student-charges`).
class StudentChargePageDto implements KeysetPageDto<StudentChargeDto> {
  @override
  final List<StudentChargeDto> items;
  @override
  final KeysetPageEnvelope page;

  const StudentChargePageDto({required this.items, required this.page});

  factory StudentChargePageDto.fromJson(Map<String, dynamic> j) =>
      StudentChargePageDto(
        items: _lenientList(j['items'], StudentChargeDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}

/// Allocation NESTED du pull paiements (schéma minimal `PaymentDelta.allocations`
/// : `id, studentChargeId?, feeCode, amountInCents`) — ni `paymentId` (parent),
/// ni `studentChargeLabel`, ni `currency` (repris du paiement parent).
class PaymentPullAllocationDto {
  final String id;
  final String? studentChargeId;
  final String feeCode;
  final int amountInCents;

  const PaymentPullAllocationDto({
    required this.id,
    this.studentChargeId,
    required this.feeCode,
    required this.amountInCents,
  });

  factory PaymentPullAllocationDto.fromJson(Map<String, dynamic> j) =>
      PaymentPullAllocationDto(
        id: j['id'] as String,
        studentChargeId: j['studentChargeId'] as String?,
        feeCode: j['feeCode'] as String,
        amountInCents: (j['amountInCents'] as num).toInt(),
      );

  PaymentAllocationLocalModel toLocalModel({
    required String paymentId,
    required String currency,
  }) => PaymentAllocationLocalModel(
    id: id,
    clientUuid: id,
    paymentId: paymentId,
    studentChargeId: studentChargeId,
    feeCode: feeCode,
    // Le pull ne porte pas le libellé de la créance → repli sur le fee_code.
    studentChargeLabel: feeCode,
    amountInCents: amountInCents,
    currency: currency,
  );
}

/// Item du pull paiements : un paiement (autoritaire, SYNCED) + ses allocations.
class PaymentDeltaDto {
  final PaymentDto payment;
  final List<PaymentPullAllocationDto> allocations;

  const PaymentDeltaDto({required this.payment, required this.allocations});

  factory PaymentDeltaDto.fromJson(Map<String, dynamic> j) => PaymentDeltaDto(
    payment: PaymentDto.fromJson(j),
    allocations: (j['allocations'] as List<dynamic>? ?? const [])
        .map(
          (e) => PaymentPullAllocationDto.fromJson(e as Map<String, dynamic>),
        )
        .toList(),
  );

  List<PaymentAllocationLocalModel> allocationModels() => allocations
      .map(
        (a) =>
            a.toLocalModel(paymentId: payment.id, currency: payment.currency),
      )
      .toList();
}

/// Page keyset des paiements (`GET /api/v1/sync/payments`).
class PaymentPageDto implements KeysetPageDto<PaymentDeltaDto> {
  @override
  final List<PaymentDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const PaymentPageDto({required this.items, required this.page});

  factory PaymentPageDto.fromJson(Map<String, dynamic> j) => PaymentPageDto(
    items: _lenientList(j['items'], PaymentDeltaDto.fromJson),
    page: KeysetPageEnvelope.fromJson(j),
  );
}
