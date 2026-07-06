// DTOs de pull delta (FF-Lot 2). Grille tarifaire + grand-livre autoritaire.
// Réponses serveur (fromJson) → converties en modèles locaux au upsert.

import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';

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
    status: status,
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

class PaymentAllocationDto {
  final String id;
  final String paymentId;
  final String? studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const PaymentAllocationDto({
    required this.id,
    required this.paymentId,
    this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  factory PaymentAllocationDto.fromJson(Map<String, dynamic> j) =>
      PaymentAllocationDto(
        id: j['id'] as String,
        paymentId: j['paymentId'] as String,
        studentChargeId: j['studentChargeId'] as String?,
        feeCode: j['feeCode'] as String,
        studentChargeLabel: (j['studentChargeLabel'] as String?) ?? '',
        amountInCents: (j['amountInCents'] as num).toInt(),
        currency: j['currency'] as String,
      );

  PaymentAllocationLocalModel toLocalModel() => PaymentAllocationLocalModel(
    id: id,
    clientUuid: id,
    paymentId: paymentId,
    studentChargeId: studentChargeId,
    feeCode: feeCode,
    studentChargeLabel: studentChargeLabel,
    amountInCents: amountInCents,
    currency: currency,
  );
}

/// Delta de grille tarifaire.
class FeeTariffDelta {
  final List<FeeTariffDto> tariffs;
  final int? serverCursor;

  const FeeTariffDelta({this.tariffs = const [], this.serverCursor});

  factory FeeTariffDelta.fromJson(Map<String, dynamic> j) => FeeTariffDelta(
    tariffs: (j['tariffs'] as List<dynamic>? ?? const [])
        .map((e) => FeeTariffDto.fromJson(e as Map<String, dynamic>))
        .toList(),
    serverCursor: (j['serverCursor'] as num?)?.toInt(),
  );
}

/// Delta du grand-livre : créances autoritaires + paiements + allocations.
class LedgerDelta {
  final List<StudentChargeDto> charges;
  final List<PaymentDto> payments;
  final List<PaymentAllocationDto> allocations;
  final int? serverCursor;

  const LedgerDelta({
    this.charges = const [],
    this.payments = const [],
    this.allocations = const [],
    this.serverCursor,
  });

  factory LedgerDelta.fromJson(Map<String, dynamic> j) => LedgerDelta(
    charges: (j['charges'] as List<dynamic>? ?? const [])
        .map((e) => StudentChargeDto.fromJson(e as Map<String, dynamic>))
        .toList(),
    payments: (j['payments'] as List<dynamic>? ?? const [])
        .map((e) => PaymentDto.fromJson(e as Map<String, dynamic>))
        .toList(),
    allocations: (j['allocations'] as List<dynamic>? ?? const [])
        .map((e) => PaymentAllocationDto.fromJson(e as Map<String, dynamic>))
        .toList(),
    serverCursor: (j['serverCursor'] as num?)?.toInt(),
  );
}
