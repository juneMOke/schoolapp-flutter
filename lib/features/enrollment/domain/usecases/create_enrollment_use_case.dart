import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class CreateEnrollmentUseCase {
  final EnrollmentRepository _repository;

  const CreateEnrollmentUseCase(this._repository);

  Future<Either<Failure, EnrollmentSummary>> call({
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
    required String birthPlace,
    required String nationality,
    required String gender,
  }) {
    return _repository.createEnrollment(
      firstName: firstName,
      lastName: lastName,
      surname: surname,
      dateOfBirth: dateOfBirth,
      birthPlace: birthPlace,
      nationality: nationality,
      gender: gender,
    );
  }
}
