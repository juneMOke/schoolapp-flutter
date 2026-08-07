import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Étape 0 du wizard : crée les 2 lignes DRAFT (élève + inscription).
class SaveDraftIdentityUseCase {
  final EnrollmentOfflineRepository _repository;

  const SaveDraftIdentityUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String enrollmentId,
    required String studentId,
    required String firstName,
    required String lastName,
    String? surname,
    required String gender,
    required String dateOfBirth,
    String? birthPlace,
    String? nationality,
    String? matriculationNumber,
    required String enrollmentType,
    required String status,
    required String academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
    required String enrollmentDate,
  }) => _repository.saveDraftIdentity(
    enrollmentId: enrollmentId,
    studentId: studentId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    gender: gender,
    dateOfBirth: dateOfBirth,
    birthPlace: birthPlace,
    nationality: nationality,
    matriculationNumber: matriculationNumber,
    enrollmentType: enrollmentType,
    status: status,
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    enrollmentDate: enrollmentDate,
  );
}
