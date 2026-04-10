import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetEnrollmentSummaryListByStatusUseCase {
  final EnrollmentRepository _repository;

  const GetEnrollmentSummaryListByStatusUseCase(this._repository);

  Future<Either<Failure, List<EnrollmentSummary>>> call({
    required String status,
    required String academicYearId,
  }) {
    return _repository.getEnrollmentSummaryListByStatus(
      status: status,
      academicYearId: academicYearId,
    );
  }
}
