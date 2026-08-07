import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Sonde au tap RE : y a-t-il déjà un dossier local pour `(studentId, année)` ?
/// `null` = aucun → seed d'un brouillon depuis la cohorte ; sinon → ouverture du
/// dossier existant (reprise si DRAFT, lecture seule si finalisé).
class ProbeReenrollmentDossierUseCase {
  final EnrollmentOfflineRepository _repository;

  const ProbeReenrollmentDossierUseCase(this._repository);

  Future<Either<Failure, LocalDossierRef?>> call({
    required String studentId,
    required String academicYearId,
  }) => _repository.probeLocalReenrollmentDossier(
    studentId: studentId,
    academicYearId: academicYearId,
  );
}
