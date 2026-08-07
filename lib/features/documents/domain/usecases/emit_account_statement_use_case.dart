import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/student_year_document_params.dart';

/// Émet le relevé de compte (RL) d'un élève.
///
/// ⚠️ **Non idempotent.** Le serveur horodate la pièce, ne l'archive pas, et
/// consomme un numéro de séquence à chaque appel. L'appelant ne doit jamais
/// rejouer automatiquement cette opération après un échec : voir
/// [UncertainOutcomeFailure] et `EditiqueDocumentType.isReplayable`.
class EmitAccountStatementUseCase {
  final EditiqueRepository _repository;

  const EmitAccountStatementUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(
    StudentYearDocumentParams params,
  ) => _repository.emitAccountStatement(
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}
