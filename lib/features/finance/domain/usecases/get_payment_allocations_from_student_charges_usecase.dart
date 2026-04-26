import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/student_charges_repository.dart';

class GetPaymentAllocationsFromStudentChargesUseCase {
  final StudentChargesRepository _repository;

  const GetPaymentAllocationsFromStudentChargesUseCase(this._repository);

  Future<Either<Failure, List<PaymentAllocation>>> call(
    GetPaymentAllocationsFromStudentChargesParams params,
  ) => _repository.getPaymentAllocationsByChargeId(chargeId: params.chargeId);
}

class GetPaymentAllocationsFromStudentChargesParams extends Equatable {
  final String chargeId;

  const GetPaymentAllocationsFromStudentChargesParams({required this.chargeId});

  @override
  List<Object?> get props => [chargeId];
}
