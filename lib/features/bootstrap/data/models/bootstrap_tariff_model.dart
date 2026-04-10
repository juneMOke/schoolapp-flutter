import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_tariff.dart';

class BootstrapTariffModel {
  final String id;
  final int version;
  final String feeCode;
  final String label;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String academicYearId;
  final int amountInCents;
  final String currency;
  final DateTime dueAt;

  const BootstrapTariffModel({
    required this.id,
    required this.version,
    required this.feeCode,
    required this.label,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
  });

  factory BootstrapTariffModel.fromJson(Map<String, dynamic> json) {
    return BootstrapTariffModel(
      id: json['id'] as String,
      version: json['version'] as int? ?? 0,
      feeCode: json['feeCode'] as String,
      label: json['label'] as String,
      schoolLevelGroupId: json['schoolLevelGroupId'] as String,
      schoolLevelId: json['schoolLevelId'] as String,
      academicYearId: json['academicYearId'] as String,
      amountInCents: json['amountInCents'] as int? ?? 0,
      currency: json['currency'] as String,
      dueAt: DateTime.parse(json['dueAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'feeCode': feeCode,
    'label': label,
    'schoolLevelGroupId': schoolLevelGroupId,
    'schoolLevelId': schoolLevelId,
    'academicYearId': academicYearId,
    'amountInCents': amountInCents,
    'currency': currency,
    'dueAt': dueAt.toIso8601String(),
  };

  BootstrapTariff toEntity() {
    return BootstrapTariff(
      id: id,
      version: version,
      feeCode: feeCode,
      label: label,
      schoolLevelGroupId: schoolLevelGroupId,
      schoolLevelId: schoolLevelId,
      academicYearId: academicYearId,
      amountInCents: amountInCents,
      currency: currency,
      dueAt: dueAt,
    );
  }
}
