import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_repository.dart';

class GetSchoolLevelGroupsUseCase {
  final EnrollmentRepository _repository;

  const GetSchoolLevelGroupsUseCase(this._repository);

  Future<Either<Failure, List<SchoolLevelGroup>>> call({
    required String academicYearId,
  }) {
    return _repository.getSchoolLevelGroups(academicYearId: academicYearId);
  }
}
