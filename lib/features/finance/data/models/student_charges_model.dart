import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

part 'student_charges_model.g.dart';

@JsonSerializable()
class StudentChargesModel extends Equatable {
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
  final String status;

  const StudentChargesModel({
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

  factory StudentChargesModel.fromJson(Map<String, dynamic> json) =>
      _$StudentChargesModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudentChargesModelToJson(this);

  StudentCharge toEntity() => StudentCharge(
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
    currency: currency,
    status: StudentChargeStatusX.fromApiValue(status),
  );

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
