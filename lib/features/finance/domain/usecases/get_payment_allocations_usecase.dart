import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';

class GetPaymentAllocationsUseCase {
  final PaymentsRepository _repository;

  const GetPaymentAllocationsUseCase(this._repository);

  Future<Either<Failure, List<PaymentAllocation>>> call(
    GetPaymentAllocationsParams params,
  ) => _repository.getPaymentAllocationsByPaymentId(paymentId: params.paymentId);
}

class GetPaymentAllocationsParams extends Equatable {
  final String paymentId;

  const GetPaymentAllocationsParams({required this.paymentId});

  @override
  List<Object?> get props => [paymentId];
}
