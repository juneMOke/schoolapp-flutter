import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase {
  final EnrollmentRepository _repository;

  const SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase(
    this._repository,
  );

  Future<Either<Failure, List<EnrollmentSummary>>> call({
    required String status,
    required String academicYearId,
    required String firstName,
    required String lastName,
    required String surname,
  }) {
    return _repository
        .searchEnrollmentSummaryByStatusAndAcademicYearAndStudentName(
          status: status,
          academicYearId: academicYearId,
          firstName: firstName,
          lastName: lastName,
          surname: surname,
        );
  }
}
