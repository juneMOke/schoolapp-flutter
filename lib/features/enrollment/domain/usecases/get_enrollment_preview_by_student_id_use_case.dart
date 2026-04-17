import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetEnrollmentPreviewByStudentIdUseCase {
  final EnrollmentRepository _repository;

  const GetEnrollmentPreviewByStudentIdUseCase(this._repository);

  Future<Either<Failure, EnrollmentDetail>> call({
    required String studentId,
  }) {
    return _repository.getEnrollmentPreviewByStudentId(studentId: studentId);
  }
}
