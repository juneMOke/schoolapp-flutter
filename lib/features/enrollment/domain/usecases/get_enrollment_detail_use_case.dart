import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetEnrollmentDetailUseCase {
  final EnrollmentRepository _repository;

  const GetEnrollmentDetailUseCase(this._repository);

  Future<Either<Failure, EnrollmentDetail>> call({
    required String enrollmentId,
  }) {
    return _repository.getEnrollmentDetail(enrollmentId: enrollmentId);
  }
}
