import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Lit le détail d'un brouillon (élève + tuteurs + documents).
class GetDraftDetailUseCase {
  final EnrollmentOfflineRepository _repository;

  const GetDraftDetailUseCase(this._repository);

  Future<Either<Failure, LocalEnrollmentDetail>> call(String enrollmentId) =>
      _repository.getDraftDetail(enrollmentId);
}
