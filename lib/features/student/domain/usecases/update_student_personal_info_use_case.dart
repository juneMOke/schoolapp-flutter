import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_repository.dart';

class UpdateStudentPersonalInfoUseCase {
  final StudentRepository _repository;

  const UpdateStudentPersonalInfoUseCase(this._repository);

  Future<Either<Failure, StudentDetail>> call({
    required String studentId,
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
    required String gender,
    required String birthPlace,
    required String nationality,
  }) {
    return _repository.updateStudentPersonalInfo(
      studentId: studentId,
      firstName: firstName,
      lastName: lastName,
      surname: surname,
      dateOfBirth: dateOfBirth,
      gender: gender,
      birthPlace: birthPlace,
      nationality: nationality,
    );
  }
}
