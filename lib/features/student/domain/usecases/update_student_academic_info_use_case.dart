import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_academic_info.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_repository.dart';

class UpdateStudentAcademicInfoUseCase {
  final StudentRepository _repository;

  const UpdateStudentAcademicInfoUseCase(this._repository);

  Future<Either<Failure, StudentAcademicInfo>> call({
    required String studentId,
    required String schoolLevelId,
    required String schoolLevelGroupId,
  }) {
    return _repository.updateStudentAcademicInfo(
      studentId: studentId,
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
    );
  }
}
