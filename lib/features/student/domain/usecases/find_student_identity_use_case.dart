import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_identity_repository.dart';

/// Retrouve l'identité d'un élève et sa classe de l'année, depuis la base
/// locale : c'est ce qui rend une fiche rechargeable depuis son adresse.
class FindStudentIdentityUseCase {
  final StudentIdentityRepository _repository;

  const FindStudentIdentityUseCase(this._repository);

  Future<Either<Failure, StudentIdentity?>> call({
    required String studentId,
    required String academicYearId,
  }) => _repository.findIdentity(
    studentId: studentId,
    academicYearId: academicYearId,
  );
}
