import 'package:equatable/equatable.dart';

class PaymentAllocation extends Equatable {
  final String id;
  final String paymentId;
  final String studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  /// Identité du payeur et date du versement porteur de cette imputation
  /// (détail d'un frais §16). Repliés depuis le paiement joint : la source
  /// online (backend) ne les porte pas encore → valeurs par défaut vides /
  /// nulles, l'UI retombe alors sur « valeur inconnue ».
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final DateTime? paidAt;

  const PaymentAllocation({
    required this.id,
    required this.paymentId,
    required this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
    this.payerFirstName = '',
    this.payerLastName = '',
    this.payerMiddleName,
    this.paidAt,
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
    payerFirstName,
    payerLastName,
    payerMiddleName,
    paidAt,
  ];
}
