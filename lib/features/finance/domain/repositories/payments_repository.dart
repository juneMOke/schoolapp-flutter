import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';

class CreatePaymentAllocationInput extends Equatable {
  final String studentChargeId;
  final String feeCode;
  final String studentChargeLabel;
  final int amountInCents;
  final String currency;

  const CreatePaymentAllocationInput({
    required this.studentChargeId,
    required this.feeCode,
    required this.studentChargeLabel,
    required this.amountInCents,
    required this.currency,
  });

  @override
  List<Object?> get props => [
    studentChargeId,
    feeCode,
    studentChargeLabel,
    amountInCents,
    currency,
  ];
}

abstract class PaymentsRepository {
  Future<Either<Failure, List<Payment>>> getPaymentsByStudentAndAcademicYear({
    required String studentId,
    required String academicYearId,
  });

  Future<Either<Failure, Payment>> createPayment({
    required String studentId,
    required String academicYearId,
    required int amountInCents,
    required String currency,
    required String payerFirstName,
    required String payerLastName,
    String? payerMiddleName,
    required List<CreatePaymentAllocationInput> allocations,
  });

  Future<Either<Failure, List<PaymentAllocation>>>
  getPaymentAllocationsByPaymentId({
    required String paymentId,
  });
}