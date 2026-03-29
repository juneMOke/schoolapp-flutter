import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class SearchStudentsUseCase {
  final EnrollmentRepository _repository;

  const SearchStudentsUseCase(this._repository);

  Future<Either<Failure, List<StudentSummary>>> call({
    String? firstName,
    String? lastName,
    String? middleName,
    required String academicYearId,
  }) {
    return _repository.searchStudents(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      academicYearId: academicYearId,
    );
  }
}
