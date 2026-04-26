import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';

class CreatePaymentUseCase {
  final PaymentsRepository _repository;

  const CreatePaymentUseCase(this._repository);

  Future<Either<Failure, Payment>> call({
    required String studentId,
    required String academicYearId,
    required int amountInCents,
    required String currency,
    required String payerFirstName,
    required String payerLastName,
    String? payerMiddleName,
    required List<CreatePaymentAllocationInput> allocations,
  }) => _repository.createPayment(
    studentId: studentId,
    academicYearId: academicYearId,
    amountInCents: amountInCents,
    currency: currency,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    allocations: allocations,
  );
}
