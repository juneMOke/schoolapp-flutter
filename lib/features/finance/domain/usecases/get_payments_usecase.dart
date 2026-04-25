import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';

class GetPaymentsUseCase {
  final PaymentsRepository _repository;

  const GetPaymentsUseCase(this._repository);

  Future<Either<Failure, List<Payment>>> call(GetPaymentsParams params) =>
      _repository.getPaymentsByStudentAndAcademicYear(
        studentId: params.studentId,
        academicYearId: params.academicYearId,
      );
}

class GetPaymentsParams extends Equatable {
  final String studentId;
  final String academicYearId;

  const GetPaymentsParams({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}