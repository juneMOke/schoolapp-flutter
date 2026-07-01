import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/notation_repository.dart';

/// Charge la grille de saisie : les élèves de la classe du cours + leur note
/// pour l'évaluation [evaluationId].
class GetNotesElevesUseCase {
  final NotationRepository _repository;

  const GetNotesElevesUseCase(this._repository);

  Future<Either<Failure, List<NoteEleve>>> call(String evaluationId) =>
      _repository.getNotesEleves(evaluationId);
}
