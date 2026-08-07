import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Préinscription locale (`ref_pre_enrollments`) par `id` — photo de départ du
/// brouillon PRE lue depuis le local (plus d'appel serveur).
class GetPreEnrollmentUseCase {
  final EnrollmentOfflineRepository _repository;

  const GetPreEnrollmentUseCase(this._repository);

  Future<Either<Failure, PreEnrollmentCandidate>> call(
    String preEnrollmentId,
  ) => _repository.getPreEnrollment(preEnrollmentId);
}
