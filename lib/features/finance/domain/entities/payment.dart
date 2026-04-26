import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;
  final int amountInCents;
  final String currency;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final DateTime paidAt;

  const Payment({
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