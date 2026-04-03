import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/data/datasources/academic_year_local_data_source.dart';
import 'package:school_app_flutter/features/academic_year/data/models/academic_year_model.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_local_repository.dart';

class AcademicYearLocalRepositoryImpl implements AcademicYearLocalRepository {
  final AcademicYearLocalDataSource localDataSource;

  const AcademicYearLocalRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, AcademicYear>> getStoredAcademicYear() async {
    try {
      final model = await localDataSource.readAcademicYear();
      if (model == null) {
        return const Left(StorageFailure('No stored academic year found'));
      }
      return Right(model.toAcademicYear());
    } catch (_) {
      return const Left(StorageFailure('Failed to read academic year'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAcademicYear({
    required AcademicYear academicYear,
  }) async {
    try {
      await localDataSource.saveAcademicYear(
        AcademicYearModel(
          id: academicYear.id,
          name: academicYear.name,
          startDate: academicYear.startDate,
          endDate: academicYear.endDate,
          current: academicYear.current,
        ),
      );
      return const Right(null);
    } catch (_) {
      return const Left(StorageFailure('Failed to save academic year'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAcademicYear() async {
    try {
      await localDataSource.clearAcademicYear();
      return const Right(null);
    } catch (_) {
      return const Left(StorageFailure('Failed to clear academic year'));
    }
  }
}
