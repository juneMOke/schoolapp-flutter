import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase {
  final EnrollmentRepository _repository;

  const SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase(
    this._repository,
  );

  Future<Either<Failure, List<EnrollmentSummary>>> call({
    required String status,
    required String academicYearId,
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
  }) {
    return _repository
        .searchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirth(
          status: status,
          academicYearId: academicYearId,
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          dateOfBirth: dateOfBirth,
        );
  }
}
