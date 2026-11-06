import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_request.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/repositories/level_correction_repository.dart';

/// Pose une correction de niveau. `Right(false)` : une autre attend déjà.
class CorrectLevelUseCase {
  final LevelCorrectionRepository _repository;

  const CorrectLevelUseCase(this._repository);

  Future<Either<Failure, bool>> call(LevelCorrectionRequest request) =>
      _repository.correct(request);
}

/// La dernière correction d'une inscription.
class LoadLevelCorrectionUseCase {
  final LevelCorrectionRepository _repository;

  const LoadLevelCorrectionUseCase(this._repository);

  Future<Either<Failure, LevelCorrection?>> call(String enrollmentId) =>
      _repository.latestFor(enrollmentId);
}

/// L'encaissement de l'élève est-il retenu par sa correction de niveau (D7) ?
class IsCollectionHeldByLevelCorrectionUseCase {
  final LevelCorrectionRepository _repository;

  const IsCollectionHeldByLevelCorrectionUseCase(this._repository);

  Future<Either<Failure, bool>> call({
    required String studentId,
    required String academicYearId,
  }) => _repository.holdsCollection(
    studentId: studentId,
    academicYearId: academicYearId,
  );
}
