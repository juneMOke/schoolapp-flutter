import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Modèle de la table `ref_fee_tariffs`.
class FeeTariffLocalModel {
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
  final int? syncedAt;
  final int updatedAt;

  const FeeTariffLocalModel({
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
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'academic_year_id': academicYearId,
    'school_level_id': schoolLevelId,
    'school_level_group_id': schoolLevelGroupId,
    'fee_code': feeCode,
    'label': label,
    'amount_in_cents': amountInCents,
    'currency': currency,
    'due_at': dueAt,
    'version': version,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  factory FeeTariffLocalModel.fromMap(Map<String, Object?> m) =>
      FeeTariffLocalModel(
        id: m['id'] as String,
        academicYearId: m['academic_year_id'] as String?,
        schoolLevelId: m['school_level_id'] as String?,
        schoolLevelGroupId: m['school_level_group_id'] as String?,
        feeCode: m['fee_code'] as String,
        label: m['label'] as String,
        amountInCents: (m['amount_in_cents'] as int?) ?? 0,
        currency: m['currency'] as String,
        dueAt: m['due_at'] as String?,
        version: (m['version'] as int?) ?? 0,
        syncedAt: m['synced_at'] as int?,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  LocalFeeTariff toEntity() => LocalFeeTariff(
    id: id,
    feeCode: feeCode,
    label: label,
    amountInCents: amountInCents,
    currency: currency,
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    dueAt: dueAt,
    version: version,
  );
}

/// Modèle de la table `student_charges`.
class StudentChargeLocalModel {
  final String id;
  final String studentId;
  final String? academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String? feeTariffId;
  final String feeCode;
  final String label;
  final int expectedAmountInCents;
  final int amountPaidInCents;
  // GELÉE (vestigiale) : le reste se compose désormais à la lecture (FRONT §5).
  // Plus jamais incrémentée par le poste ; conservée pour compat de colonne, à
  // retirer à un futur bump de schéma.
  final int optimisticPaidInCents;
  final String currency;
  final String status;
  final String? dueAt;
  final int version;
  final String syncStatus;
  final int? syncedAt;
  final int updatedAt;

  const StudentChargeLocalModel({
    required this.id,
    required this.studentId,
    this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    this.feeTariffId,
    required this.feeCode,
    required this.label,
    required this.expectedAmountInCents,
    this.amountPaidInCents = 0,
    this.optimisticPaidInCents = 0,
    required this.currency,
    this.status = 'DUE',
    this.dueAt,
    this.version = 0,
    this.syncStatus = 'SYNCED',
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'student_id': studentId,
    'academic_year_id': academicYearId,
    'school_level_id': schoolLevelId,
    'school_level_group_id': schoolLevelGroupId,
    'fee_tariff_id': feeTariffId,
    'fee_code': feeCode,
    'label': label,
    'expected_amount_in_cents': expectedAmountInCents,
    'amount_paid_in_cents': amountPaidInCents,
    'optimistic_paid_in_cents': optimisticPaidInCents,
    'currency': currency,
    'status': status,
    'due_at': dueAt,
    'version': version,
    'sync_status': syncStatus,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  factory StudentChargeLocalModel.fromMap(Map<String, Object?> m) =>
      StudentChargeLocalModel(
        id: m['id'] as String,
        studentId: m['student_id'] as String,
        academicYearId: m['academic_year_id'] as String?,
        schoolLevelId: m['school_level_id'] as String?,
        schoolLevelGroupId: m['school_level_group_id'] as String?,
        feeTariffId: m['fee_tariff_id'] as String?,
        feeCode: m['fee_code'] as String,
        label: m['label'] as String,
        expectedAmountInCents: (m['expected_amount_in_cents'] as int?) ?? 0,
        amountPaidInCents: (m['amount_paid_in_cents'] as int?) ?? 0,
        optimisticPaidInCents: (m['optimistic_paid_in_cents'] as int?) ?? 0,
        currency: m['currency'] as String,
        status: (m['status'] as String?) ?? 'DUE',
        dueAt: m['due_at'] as String?,
        version: (m['version'] as int?) ?? 0,
        syncStatus: (m['sync_status'] as String?) ?? 'SYNCED',
        syncedAt: m['synced_at'] as int?,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  /// [paidPending] = Σ des allocations de ce poste non encore remontées,
  /// **composée à la lecture** par le DAO (FRONT §5). Absente (0) → créance
  /// sans encaissement local en attente (miroir serveur seul).
  LocalStudentCharge toEntity({int paidPending = 0}) => LocalStudentCharge(
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
    amountPaidPendingInCents: paidPending,
    currency: currency,
    status: StudentChargeStatusX.fromApiValue(status),
    dueAt: dueAt,
    version: version,
    syncState: SyncState.fromDbValue(syncStatus),
  );
}

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

  LocalPaymentAllocation toEntity() => LocalPaymentAllocation(
    id: id,
    paymentId: paymentId,
    studentChargeId: studentChargeId,
    feeCode: feeCode,
    studentChargeLabel: studentChargeLabel,
    amountInCents: amountInCents,
    currency: currency,
  );
}
