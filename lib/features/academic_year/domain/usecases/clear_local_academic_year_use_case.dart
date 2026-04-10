import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_local_repository.dart';

class ClearLocalAcademicYearUseCase {
  final AcademicYearLocalRepository _repository;

  const ClearLocalAcademicYearUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.clearAcademicYear();
  }
}
