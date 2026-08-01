import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/student_year_document_params.dart';

/// Émet la note de perception annuelle (NP) d'un élève.
///
/// Pièce archivée et idempotente. Le serveur répond 404 lorsque l'élève n'a
/// aucune charge sur l'année, et 422 lorsque ses charges mêlent plusieurs
/// devises.
class EmitNotePerceptionUseCase {
  final EditiqueRepository _repository;

  const EmitNotePerceptionUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(
    StudentYearDocumentParams params,
  ) => _repository.emitNotePerception(
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}
