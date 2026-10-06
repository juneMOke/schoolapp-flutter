import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/ressource_draft.dart';

/// Les notes de séance et les ressources d'un chapitre.
abstract class ChapitreChildrenRepository {
  Future<Either<Failure, Unit>> addNote(Chapitre chapitre, String texte);

  Future<Either<Failure, Unit>> deleteNote(String noteId);

  Future<Either<Failure, Unit>> addRessource(
    Chapitre chapitre,
    RessourceDraft draft,
  );

  Future<Either<Failure, Unit>> deleteRessource(String ressourceId);

  /// Les octets d'un document : copie de la tablette, sinon téléchargés (et
  /// gardés) à la demande.
  Future<Either<Failure, Uint8List>> openDocument(ChapitreRessource ressource);
}
