import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Recherches locales (nom / date de naissance / info académique).
class SearchLocalEnrollmentsUseCase {
  final EnrollmentOfflineRepository _repository;

  const SearchLocalEnrollmentsUseCase(this._repository);

  Future<Either<Failure, List<LocalEnrollmentListItem>>> byName(String query) =>
      _repository.searchByName(query);

  Future<Either<Failure, List<LocalEnrollmentListItem>>> byDateOfBirth(
    String dateOfBirth,
  ) => _repository.searchByDateOfBirth(dateOfBirth);

  Future<Either<Failure, List<LocalEnrollmentListItem>>> byAcademicInfo({
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) => _repository.searchByAcademicInfo(
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
  );
}
