import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Recherche locale de **réinscription** : le vivier N-1 (cohorte
/// `ref_previous_year_students`, filtré niveau) + les dossiers RE locaux de
/// l'année courante, pour la superposition read-your-writes. Le raffinement
/// nom/surnom/DOB et la déduplication par `studentId` sont faits côté
/// présentation (le DAO ne scope que le niveau).
class SearchLocalEnrollmentsUseCase {
  final EnrollmentOfflineRepository _repository;

  const SearchLocalEnrollmentsUseCase(this._repository);

  Future<Either<Failure, ReenrollmentSearchResult>> byCohort({
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) => _repository.searchReenrollmentCohort(
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
  );
}
