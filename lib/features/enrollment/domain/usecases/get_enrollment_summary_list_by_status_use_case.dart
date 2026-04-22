import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary_page.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetEnrollmentSummaryListByStatusUseCase {
  final EnrollmentRepository _repository;

  const GetEnrollmentSummaryListByStatusUseCase(this._repository);

  Future<Either<Failure, EnrollmentSummaryPage>> call({
    required String status,
    required String academicYearId,
    int page = 0,
    int size = AppConstants.enrollmentDefaultPageSize,
  }) {
    return _repository.getEnrollmentSummaryListByStatus(
      status: status,
      academicYearId: academicYearId,
      page: page,
      size: size,
    );
  }
}
