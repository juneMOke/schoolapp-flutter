import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_repository.dart';

class UpdateStudentAddressUseCase {
  final StudentRepository _repository;

  const UpdateStudentAddressUseCase(this._repository);

  Future<Either<Failure, StudentDetail>> call({
    required String studentId,
    required String city,
    required String district,
    required String municipality,
    required String address,
  }) {
    return _repository.updateStudentAddress(
      studentId: studentId,
      city: city,
      district: district,
      municipality: municipality,
      address: address,
    );
  }
}
