import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase {
  final EnrollmentRepository _repository;

  const SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase(
    this._repository,
  );

  Future<Either<Failure, List<EnrollmentSummary>>> call({
    required String status,
    required String academicYearId,
    required String dateOfBirth,
  }) {
    return _repository
        .searchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirth(
          status: status,
          academicYearId: academicYearId,
          dateOfBirth: dateOfBirth,
        );
  }
}
