import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';

/// Ce que la tablette sait pour proposer une correction de niveau.
abstract class LevelCorrectionOptionsRepository {
  /// Les classes de l'année et la classe actuelle de l'élève.
  Future<Either<Failure, LevelCorrectionClassrooms>> classrooms({
    required String studentId,
    required String academicYearId,
  });
}

/// Les classes qu'une correction peut viser.
class LoadLevelCorrectionClassroomsUseCase {
  final LevelCorrectionOptionsRepository _repository;

  const LoadLevelCorrectionClassroomsUseCase(this._repository);

  Future<Either<Failure, LevelCorrectionClassrooms>> call({
    required String studentId,
    required String academicYearId,
  }) => _repository.classrooms(
    studentId: studentId,
    academicYearId: academicYearId,
  );
}
