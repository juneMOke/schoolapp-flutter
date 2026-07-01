import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/notation_repository.dart';

/// Saisit ou met à jour (rattrapage) la note d'un élève pour une évaluation.
///
/// On passe [evaluationId] directement (path param) et le corps via le modèle de
/// requête [SaisirNoteRequest] (porteur de ses invariants statut/points).
class SaisirNoteUseCase {
  final NotationRepository _repository;

  const SaisirNoteUseCase(this._repository);

  Future<Either<Failure, NoteEvaluation>> call(
    String evaluationId,
    SaisirNoteRequest request,
  ) => _repository.saisirNote(evaluationId, request);
}
