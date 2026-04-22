import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class UpdateEnrollmentStatusUseCase {
  final EnrollmentRepository _repository;

  const UpdateEnrollmentStatusUseCase(this._repository);

  Future<Either<Failure, EnrollmentSummary>> call({
    required String enrollmentId,
    required String status,
  }) {
    return _repository.updateEnrollmentStatus(
      enrollmentId: enrollmentId,
      status: status,
    );
  }
}
