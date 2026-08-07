import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Candidat de réinscription (cohorte N-1 locale) par `student_id` — photo de
/// départ du brouillon RE lue depuis le local (plus d'appel serveur).
class GetReenrollmentCandidateUseCase {
  final EnrollmentOfflineRepository _repository;

  const GetReenrollmentCandidateUseCase(this._repository);

  Future<Either<Failure, ReenrollmentCandidate>> call(String studentId) =>
      _repository.getReenrollmentCandidate(studentId);
}
