import 'package:equatable/equatable.dart';

enum StudentChargeStatus { due, partial, paid }

extension StudentChargeStatusX on StudentChargeStatus {
  static StudentChargeStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'DUE':
        return StudentChargeStatus.due;
      case 'PARTIAL':
        return StudentChargeStatus.partial;
      case 'PAID':
        return StudentChargeStatus.paid;
      default:
        return StudentChargeStatus.due;
    }
  }
}

class StudentCharge extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;
  final String schoolLevelId;
  final String schoolLevelGroupId;
  final String feeTariffId;
  final String feeCode;
  final String label;
  final double expectedAmountInCents;
  final double amountPaidInCents;
  final String currency;
  final StudentChargeStatus status;

  const StudentCharge({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
    required this.feeTariffId,
    required this.feeCode,
    required this.label,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    required this.currency,
    required this.status,
  });

  StudentCharge copyWith({
    String? id,
    String? studentId,
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
    String? feeTariffId,
    String? feeCode,
    String? label,
    double? expectedAmountInCents,
    double? amountPaidInCents,
    String? currency,
    StudentChargeStatus? status,
  }) {
    return StudentCharge(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      academicYearId: academicYearId ?? this.academicYearId,
      schoolLevelId: schoolLevelId ?? this.schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId ?? this.schoolLevelGroupId,
      feeTariffId: feeTariffId ?? this.feeTariffId,
      feeCode: feeCode ?? this.feeCode,
      label: label ?? this.label,
      expectedAmountInCents:
          expectedAmountInCents ?? this.expectedAmountInCents,
      amountPaidInCents: amountPaidInCents ?? this.amountPaidInCents,
      currency: currency ?? this.currency,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    feeTariffId,
    feeCode,
    label,
    expectedAmountInCents,
    amountPaidInCents,
    currency,
    status,
  ];
}
