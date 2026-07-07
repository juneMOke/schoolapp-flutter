import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Étape Antécédents scolaires du wizard : UPDATE partiel de l'inscription DRAFT.
class SaveDraftPreviousAcademicUseCase {
  final EnrollmentOfflineRepository _repository;

  const SaveDraftPreviousAcademicUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String enrollmentId,
    String? previousSchoolName,
    String? previousAcademicYear,
    String? previousSchoolLevelGroup,
    String? previousSchoolLevel,
    double? previousRate,
    int? previousRank,
    bool? validatedPreviousYear,
    String? transferReason,
  }) => _repository.saveDraftPreviousAcademic(
    enrollmentId: enrollmentId,
    previousSchoolName: previousSchoolName,
    previousAcademicYear: previousAcademicYear,
    previousSchoolLevelGroup: previousSchoolLevelGroup,
    previousSchoolLevel: previousSchoolLevel,
    previousRate: previousRate,
    previousRank: previousRank,
    validatedPreviousYear: validatedPreviousYear,
    transferReason: transferReason,
  );
}
