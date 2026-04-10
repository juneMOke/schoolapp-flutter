import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';

abstract class AcademicYearRemoteRepository {
  Future<Either<Failure, AcademicYear>> getAcademicYearBySchoolId({
    required String schoolId,
  });
}
