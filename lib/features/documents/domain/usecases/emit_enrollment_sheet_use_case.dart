import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_enrollment_attestation_use_case.dart';

/// Les paramètres d'une pièce de dossier : les mêmes que l'attestation.
typedef EmitEnrollmentSheetParams = EmitEnrollmentAttestationParams;

/// Émet la fiche d'inscription (FI) d'un dossier.
///
/// Une seule en vigueur par (élève, année) : à contenu inchangé le serveur
/// re-sert la même pièce, sinon il annule l'ancienne et en scelle une
/// nouvelle. Rejouer est donc sûr.
class EmitEnrollmentSheetUseCase {
  final EditiqueRepository _repository;

  const EmitEnrollmentSheetUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(
    EmitEnrollmentSheetParams params,
  ) => _repository.emitEnrollmentSheet(
    enrollmentId: params.enrollmentId,
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}
