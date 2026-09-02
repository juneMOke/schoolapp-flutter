import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class CreatePaymentUseCase {
  final PaymentsRepository _repository;

  const CreatePaymentUseCase(this._repository);

  Future<Either<Failure, Payment>> call({
    required String studentId,
    required String academicYearId,
    required MoneyBag amounts,
    String? payerFirstName,
    String? payerLastName,
    String? payerMiddleName,
    String? payerPhoneNumber,
    required List<CreatePaymentAllocationInput> allocations,
  }) => _repository.createPayment(
    studentId: studentId,
    academicYearId: academicYearId,
    amounts: amounts,
    payerFirstName: payerFirstName,
    payerLastName: payerLastName,
    payerMiddleName: payerMiddleName,
    payerPhoneNumber: payerPhoneNumber,
    allocations: allocations,
  );
}
