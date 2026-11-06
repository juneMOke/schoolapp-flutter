import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_options_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/repositories/level_correction_options_repository.dart';

class LevelCorrectionOptionsRepositoryImpl
    implements LevelCorrectionOptionsRepository {
  final LevelCorrectionOptionsDao _dao;

  const LevelCorrectionOptionsRepositoryImpl(this._dao);

  @override
  Future<Either<Failure, LevelCorrectionClassrooms>> classrooms({
    required String studentId,
    required String academicYearId,
  }) async {
    try {
      return Right(
        await _dao.classrooms(
          studentId: studentId,
          academicYearId: academicYearId,
        ),
      );
    } catch (e) {
      return Left(StorageFailure('Lecture des classes : $e'));
    }
  }
}
