import 'package:equatable/equatable.dart';

class PaymentAllocation extends Equatable {
  final String id;
  final String paymentId;
  final String studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const PaymentAllocation({
    required this.id,
    required this.paymentId,
    required this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

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
