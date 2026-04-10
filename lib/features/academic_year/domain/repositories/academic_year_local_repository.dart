import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';

abstract class AcademicYearLocalRepository {
  Future<Either<Failure, AcademicYear>> getStoredAcademicYear();
  Future<Either<Failure, void>> saveAcademicYear({
    required AcademicYear academicYear,
  });
  Future<Either<Failure, void>> clearAcademicYear();
}
