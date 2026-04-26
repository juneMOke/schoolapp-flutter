import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';

part 'payments_model.g.dart';

@JsonSerializable()
class PaymentModel extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;
  final int amountInCents;
  final String currency;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final DateTime paidAt;

  const PaymentModel({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    required this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);

  Payment toEntity() => Payment(
    id: id,
    studentId: studentId,
    academicYearId: academicYearId,
    amountInCents: amountInCents,
    currency: currency,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    paidAt: paidAt,
  );

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    amountInCents,
    currency,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    paidAt,
  ];
}