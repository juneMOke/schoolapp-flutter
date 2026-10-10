import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspended_member.dart';
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

/// Les élèves désactivés de l'année et leur classe d'origine, et leurs
/// changements.
class LoadSuspendedMembersUseCase {
  final EnrollmentSuspensionRepository _repository;

  const LoadSuspendedMembersUseCase(this._repository);

  Future<Either<Failure, List<SuspendedMember>>> call(String academicYearId) =>
      _repository.suspendedMembers(academicYearId);

  Stream<Set<String>> get changes => _repository.changes;
}

/// La cible d'un geste depuis un membre de classe, qui ne porte pas son
/// inscription.
class ResolveSuspensionTargetUseCase {
  final EnrollmentSuspensionRepository _repository;

  const ResolveSuspensionTargetUseCase(this._repository);

  Future<Either<Failure, SuspensionTarget?>> call({
    required String studentId,
    required String academicYearId,
  }) => _repository.targetOf(
    studentId: studentId,
    academicYearId: academicYearId,
  );
}
