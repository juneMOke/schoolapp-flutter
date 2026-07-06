import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Liste locale des dossiers (option : filtre par statut métier).
class GetLocalEnrollmentsUseCase {
  final EnrollmentOfflineRepository _repository;

  const GetLocalEnrollmentsUseCase(this._repository);

  Future<Either<Failure, List<LocalEnrollmentListItem>>> call({
    String? status,
  }) => _repository.getEnrollments(status: status);
}
