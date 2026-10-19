import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';

/// Lecture locale de l'identité d'un élève, sans réseau.
abstract class StudentIdentityRepository {
  /// `Right(null)` : l'élève n'est pas sur cette tablette.
  Future<Either<Failure, StudentIdentity?>> findIdentity({
    required String studentId,
    required String academicYearId,
  });
}
