import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_remote_repository.dart';

class GetRemoteAcademicYearUseCase {
  final AcademicYearRemoteRepository _repository;

  const GetRemoteAcademicYearUseCase(this._repository);

  Future<Either<Failure, AcademicYear>> call({required String schoolId}) {
    return _repository.getAcademicYearBySchoolId(schoolId: schoolId);
  }
}
