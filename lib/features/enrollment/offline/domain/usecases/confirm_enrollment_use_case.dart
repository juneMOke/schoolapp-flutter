import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Confirme un dossier d'inscription en local-first (retour immédiat).
class ConfirmEnrollmentUseCase {
  final EnrollmentOfflineRepository _repository;

  const ConfirmEnrollmentUseCase(this._repository);

  Future<Either<Failure, String>> call(ConfirmEnrollmentDraft draft) =>
      _repository.confirmEnrollment(draft);
}
