import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetStudentDetailUseCase {
  final EnrollmentRepository _repository;

  const GetStudentDetailUseCase(this._repository);

  Future<Either<Failure, StudentDetail>> call({
    required String enrollmentId,
  }) {
    return _repository.getStudentDetail(enrollmentId: enrollmentId);
  }
}
