import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Étape Affectation du wizard : UPDATE partiel de l'inscription DRAFT (niveau
/// visé).
class SaveDraftTargetAcademicUseCase {
  final EnrollmentOfflineRepository _repository;

  const SaveDraftTargetAcademicUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String enrollmentId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) => _repository.saveDraftTargetAcademic(
    enrollmentId: enrollmentId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
  );
}
