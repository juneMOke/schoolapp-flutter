import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';

abstract class ClassroomRepository {
  Future<Either<Failure, List<Classroom>>> getClassroomsByLevelAndAcademicYear({
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required String academicYearId,
  });

  Future<Either<Failure, void>> distributeStudentsToClassrooms({
    required String academicYearId,
    required String schoolLevelGroupId,
    required String schoolLevelId,
    required ClassroomDistributionCriterion distributionCriterion,
  });
}
