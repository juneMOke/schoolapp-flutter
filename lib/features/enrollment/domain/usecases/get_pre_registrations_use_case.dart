import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetPreRegistrationsUseCase {
  final EnrollmentRepository _repository;

  const GetPreRegistrationsUseCase(this._repository);

  Future<Either<Failure, List<StudentSummary>>> call({
    required String status,
    required String academicYearId,
  }) {
    return _repository.getPreRegistrations(
      status: status,
      academicYearId: academicYearId,
    );
  }
}
