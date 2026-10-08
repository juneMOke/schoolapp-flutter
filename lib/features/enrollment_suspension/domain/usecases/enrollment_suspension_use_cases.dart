import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/repositories/enrollment_suspension_repository.dart';

/// Désactive un ou plusieurs élèves inscrits.
class SuspendStudentsUseCase {
  final EnrollmentSuspensionRepository _repository;

  const SuspendStudentsUseCase(this._repository);

  Future<Either<Failure, int>> call(
    List<SuspensionTarget> targets, {
    SuspensionReason? reason,
    String? precision,
  }) => _repository.suspend(targets, reason: reason, precision: precision);
}

/// Réactive un ou plusieurs élèves désactivés.
class ReactivateStudentsUseCase {
  final EnrollmentSuspensionRepository _repository;

  const ReactivateStudentsUseCase(this._repository);

  Future<Either<Failure, int>> call(List<SuspensionTarget> targets) =>
      _repository.reactivate(targets);
}

/// Les élèves désactivés de l'année, par inscription, et leurs changements.
class LoadOpenSuspensionsUseCase {
  final EnrollmentSuspensionRepository _repository;

  const LoadOpenSuspensionsUseCase(this._repository);

  Future<Either<Failure, Map<String, StudentSuspension>>> call(
    String academicYearId,
  ) => _repository.openByEnrollment(academicYearId);

  Stream<Set<String>> get changes => _repository.changes;
}

/// L'état de désactivation d'une inscription, et ses changements.
class LoadEnrollmentSuspensionUseCase {
  final EnrollmentSuspensionRepository _repository;

  const LoadEnrollmentSuspensionUseCase(this._repository);

  Future<Either<Failure, StudentSuspension?>> call(String enrollmentId) =>
      _repository.latestFor(enrollmentId);

  Stream<Set<String>> get changes => _repository.changes;
}
