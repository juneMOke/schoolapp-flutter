import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/student_year_document_params.dart';

/// Émet le quitus financier (QT) d'un élève.
///
/// ⚠️ **Non idempotent** — mêmes précautions que le relevé de compte : numéro
/// de séquence consommé à chaque appel, pièce jamais archivée, aucun rejeu
/// automatique après échec.
///
/// Le serveur émet la pièce quel que soit le solde : un élève débiteur reçoit
/// un quitus portant la mention « NON EN RÈGLE ». Ce n'est pas une erreur —
/// c'est à l'UI d'avertir avant l'émission.
class EmitFinancialClearanceUseCase {
  final EditiqueRepository _repository;

  const EmitFinancialClearanceUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(
    StudentYearDocumentParams params,
  ) => _repository.emitFinancialClearance(
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}
