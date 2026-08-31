import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Étape Adresse du wizard : UPDATE partiel de l'élève DRAFT.
class SaveDraftAddressUseCase {
  final EnrollmentOfflineRepository _repository;

  const SaveDraftAddressUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String studentId,
    String? city,
    String? district,
    String? municipality,
    String? neighborhood,
    String? address,
    String? reopenEnrollmentId,
  }) => _repository.saveDraftAddress(
    studentId: studentId,
    city: city,
    district: district,
    municipality: municipality,
    neighborhood: neighborhood,
    address: address,
    reopenEnrollmentId: reopenEnrollmentId,
  );
}
