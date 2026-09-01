import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Modèle de la table `ref_fee_tariffs`.
class FeeTariffLocalModel {
  final String id;
  final String? academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String feeCode;

  /// Ce qui distingue deux lignes de **même nature** sur un niveau (v39).
  /// `null` sur une base d'avant le palier, tant que le pull n'a pas réécrit la
  /// grille — et sur un serveur qui ne sert pas encore le champ.
  final String? code;

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
    this.code,
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
    'code': code,
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
        code: m['code'] as String?,
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
    code: code,
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
