import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Étape Tuteurs du wizard : remplace les tuteurs du brouillon.
class SaveDraftGuardiansUseCase {
  final EnrollmentOfflineRepository _repository;

  const SaveDraftGuardiansUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String studentId,
    required List<ConfirmParentDraft> parents,
    String? reopenEnrollmentId,
  }) => _repository.saveDraftGuardians(
    studentId: studentId,
    parents: parents,
    reopenEnrollmentId: reopenEnrollmentId,
  );
}
