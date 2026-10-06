import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';

// Les lectures et les gestes du programme. Statut rapide, objectif coché et
// contenu rédigé passent tous par [SaveChapitreUseCase] : la fiche part
// entière.

class LoadProgrammeUseCase {
  final ProgrammeRepository _repository;

  const LoadProgrammeUseCase(this._repository);

  Future<Either<Failure, Programme>> call(String coursId) =>
      _repository.loadProgramme(coursId);
}

class LoadChapitreUseCase {
  final ProgrammeRepository _repository;

  const LoadChapitreUseCase(this._repository);

  Future<Either<Failure, ChapitreDetail>> call(String chapitreId) =>
      _repository.loadChapitre(chapitreId);
}

class SaveChapitreUseCase {
  final ProgrammeRepository _repository;

  const SaveChapitreUseCase(this._repository);

  Future<Either<Failure, Chapitre>> call(Chapitre chapitre) =>
      _repository.saveChapitre(chapitre);
}

class DeleteChapitreUseCase {
  final ProgrammeRepository _repository;

  const DeleteChapitreUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String chapitreId) =>
      _repository.deleteChapitre(chapitreId);
}

class ReorderChapitresUseCase {
  final ProgrammeRepository _repository;

  const ReorderChapitresUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    String coursId,
    List<String> chapitreIds,
  ) => _repository.reorder(coursId, chapitreIds);
}
