part of 'payments_bloc.dart';

sealed class PaymentsEvent extends Equatable {
  const PaymentsEvent();
}

class PaymentsRequested extends PaymentsEvent {
  final String studentId;
  final String academicYearId;

  const PaymentsRequested({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}

class PaymentsAllocationsRequested extends PaymentsEvent {
  final String paymentId;

  const PaymentsAllocationsRequested({required this.paymentId});

  @override
  List<Object?> get props => [paymentId];
}

class PaymentsCreateRequested extends PaymentsEvent {
  final String studentId;
  final String academicYearId;
  final int amountInCents;
  final String currency;
  final String payerFirstName;
  final String payerLastName;
  final String? payerMiddleName;
  final List<CreatePaymentAllocationInput> allocations;

  const PaymentsCreateRequested({
    required this.studentId,
    required this.academicYearId,
    required this.amountInCents,
    required this.currency,
    required this.payerFirstName,
    required this.payerLastName,
    this.payerMiddleName,
    required this.allocations,
  });

  @override
  List<Object?> get props => [
    studentId,
    academicYearId,
    amountInCents,
    currency,
    payerFirstName,
    payerLastName,
    payerMiddleName,
    allocations,
  ];
}