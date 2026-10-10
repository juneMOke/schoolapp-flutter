import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspended_member.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_target.dart';

/// La désactivation d'élèves, lue et écrite sur la tablette. L'envoi au
/// serveur passe par l'outbox.
abstract class EnrollmentSuspensionRepository {
  /// Désactive [targets] en un lot, tout ou rien ; rend le nombre d'élèves
  /// effectivement désactivés (un élève déjà désactivé ne compte pas).
  Future<Either<Failure, int>> suspend(
    List<SuspensionTarget> targets, {
    SuspensionReason? reason,
    String? precision,
  });

  /// Réactive [targets] en un lot ; rend le nombre d'élèves réactivés.
  Future<Either<Failure, int>> reactivate(List<SuspensionTarget> targets);

  /// Les périodes ouvertes de l'année, par inscription.
  Future<Either<Failure, Map<String, StudentSuspension>>> openByEnrollment(
    String academicYearId,
  );

  /// La période qui dit l'état de l'inscription, `null` si jamais désactivée.
  Future<Either<Failure, StudentSuspension?>> latestFor(String enrollmentId);

  /// Les élèves désactivés de l'année qui ont une classe, avec elle.
  Future<Either<Failure, List<SuspendedMember>>> suspendedMembers(
    String academicYearId,
  );

  /// La cible d'un geste pour un élève et une année : son inscription
  /// complétée ; `null` si la tablette ne la tient pas.
  Future<Either<Failure, SuspensionTarget?>> targetOf({
    required String studentId,
    required String academicYearId,
  });

  /// Les inscriptions dont l'état change, au fil de l'eau ; un ensemble vide
  /// veut dire « tout peut avoir changé ».
  Stream<Set<String>> get changes;
}
