import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';

class DistributeStudentsToClassroomsUseCase {
  final ClassroomRepository _repository;

  const DistributeStudentsToClassroomsUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String academicYearId,
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required ClassroomDistributionCriterion distributionCriterion,
  }) => _repository.distributeStudentsToClassrooms(
    academicYearId: academicYearId,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
    distributionCriterion: distributionCriterion,
  );
}
