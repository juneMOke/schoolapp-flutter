import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';

/// Le programme d'un cours, lu et écrit **sur la tablette** : chaque geste
/// réussit localement d'abord, le serveur tranche plus tard dans l'accusé.
abstract class ProgrammeRepository {
  Future<Either<Failure, Programme>> loadProgramme(String coursId);

  Future<Either<Failure, ChapitreDetail>> loadChapitre(String chapitreId);

  /// Un identifiant neuf (chapitre, objectif, bloc, note, ressource).
  String newId();

  /// Enregistre la fiche entière, horodatée maintenant. Une ébauche pas
  /// encore descendue est refusée ([ValidationFailure]).
  Future<Either<Failure, Chapitre>> saveChapitre(Chapitre chapitre);

  Future<Either<Failure, Unit>> deleteChapitre(String chapitreId);

  /// Range les chapitres du cours dans l'ordre [chapitreIds] (liste complète).
  Future<Either<Failure, Unit>> reorder(
    String coursId,
    List<String> chapitreIds,
  );
}
