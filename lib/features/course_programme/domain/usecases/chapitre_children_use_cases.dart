import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/ressource_draft.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/chapitre_children_repository.dart';

// Les gestes sur les notes de séance et les ressources d'un chapitre.

class AddChapitreNoteUseCase {
  final ChapitreChildrenRepository _repository;

  const AddChapitreNoteUseCase(this._repository);

  Future<Either<Failure, Unit>> call(Chapitre chapitre, String texte) =>
      _repository.addNote(chapitre, texte);
}

class DeleteChapitreNoteUseCase {
  final ChapitreChildrenRepository _repository;

  const DeleteChapitreNoteUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String noteId) =>
      _repository.deleteNote(noteId);
}

class AddChapitreRessourceUseCase {
  final ChapitreChildrenRepository _repository;

  const AddChapitreRessourceUseCase(this._repository);

  Future<Either<Failure, Unit>> call(Chapitre chapitre, RessourceDraft draft) =>
      _repository.addRessource(chapitre, draft);
}

class DeleteChapitreRessourceUseCase {
  final ChapitreChildrenRepository _repository;

  const DeleteChapitreRessourceUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String ressourceId) =>
      _repository.deleteRessource(ressourceId);
}

class OpenChapitreDocumentUseCase {
  final ChapitreChildrenRepository _repository;

  const OpenChapitreDocumentUseCase(this._repository);

  Future<Either<Failure, Uint8List>> call(ChapitreRessource ressource) =>
      _repository.openDocument(ressource);
}
