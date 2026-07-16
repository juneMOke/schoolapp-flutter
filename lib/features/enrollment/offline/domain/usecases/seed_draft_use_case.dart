import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Amorce un brouillon complet (RE/PRE/édition) depuis un dossier chargé :
/// la photo de départ, que les étapes du wizard éditeront colonne-à-colonne.
class SeedDraftUseCase {
  final EnrollmentOfflineRepository _repository;

  const SeedDraftUseCase(this._repository);

  Future<Either<Failure, DraftIds>> call(
    ConfirmEnrollmentDraft seed, {
    String? enrollmentId,
  }) => _repository.seedDraft(seed, enrollmentId: enrollmentId);
}
