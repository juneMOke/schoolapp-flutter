import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';

part 'payment_allocations_model.g.dart';

@JsonSerializable()
class PaymentAllocationsModel extends Equatable {
  final String id;
  final String paymentId;
  final String studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const PaymentAllocationsModel({
    required this.id,
    required this.paymentId,
    required this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  factory PaymentAllocationsModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentAllocationsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentAllocationsModelToJson(this);

  PaymentAllocation toEntity() => PaymentAllocation(
    id: id,
    paymentId: paymentId,
    studentChargeId: studentChargeId,
    feeCode: feeCode,
    studentChargeLabel: studentChargeLabel,
    amountInCents: amountInCents,
    currency: currency,
  );

  @override
  List<Object?> get props => [
    id,
    paymentId,
    studentChargeId,
    feeCode,
    studentChargeLabel,
    amountInCents,
    currency,
  ];
}
