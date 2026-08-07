import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

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
