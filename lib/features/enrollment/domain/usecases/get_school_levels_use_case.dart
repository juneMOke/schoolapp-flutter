import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetSchoolLevelsUseCase {
  final EnrollmentRepository _repository;

  const GetSchoolLevelsUseCase(this._repository);

  Future<Either<Failure, List<SchoolLevel>>> call({
    required String levelGroupId,
    required String academicYearId,
  }) {
    return _repository.getSchoolLevels(
      levelGroupId: levelGroupId,
      academicYearId: academicYearId,
    );
  }
}
