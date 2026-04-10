import 'package:equatable/equatable.dart';

class BootstrapTariff extends Equatable {
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

  const BootstrapTariff({
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

  @override
  List<Object?> get props => [
    id,
    version,
    feeCode,
    label,
    schoolLevelGroupId,
    schoolLevelId,
    academicYearId,
    amountInCents,
    currency,
    dueAt,
  ];
}
