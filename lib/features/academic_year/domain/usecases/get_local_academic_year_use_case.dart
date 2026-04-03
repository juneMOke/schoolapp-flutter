import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_local_repository.dart';

class GetLocalAcademicYearUseCase {
  final AcademicYearLocalRepository _repository;

  const GetLocalAcademicYearUseCase(this._repository);

  Future<Either<Failure, AcademicYear>> call() {
    return _repository.getStoredAcademicYear();
  }
}
