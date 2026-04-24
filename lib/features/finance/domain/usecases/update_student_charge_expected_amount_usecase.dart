import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/student_charges_repository.dart';

class UpdateStudentChargeExpectedAmountUseCase {
  final StudentChargesRepository _repository;

  const UpdateStudentChargeExpectedAmountUseCase(this._repository);

  Future<Either<Failure, StudentCharge>> call(
    UpdateStudentChargeExpectedAmountParams params,
  ) => _repository.updateStudentChargeExpectedAmount(
    studentChargeId: params.studentChargeId,
    studentId: params.studentId,
    expectedAmountInCents: params.expectedAmountInCents,
  );
}

class UpdateStudentChargeExpectedAmountParams extends Equatable {
  final String studentChargeId;
  final String studentId;
  final double expectedAmountInCents;

  const UpdateStudentChargeExpectedAmountParams({
    required this.studentChargeId,
    required this.studentId,
    required this.expectedAmountInCents,
  });

  @override
  List<Object?> get props => [
    studentChargeId,
    studentId,
    expectedAmountInCents,
  ];
}
