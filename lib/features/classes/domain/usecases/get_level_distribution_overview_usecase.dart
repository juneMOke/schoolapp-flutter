import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';

class GetLevelDistributionOverviewUseCase {
  final ClassroomRepository _repository;

  const GetLevelDistributionOverviewUseCase(this._repository);

  Future<Either<Failure, LevelDistributionOverview>> call({
    required String academicYearId,
    required String schoolLevelId,
  }) => _repository.getLevelDistributionOverview(
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
  );
}
