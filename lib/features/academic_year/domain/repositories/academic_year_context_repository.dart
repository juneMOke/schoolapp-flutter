import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';

/// Résolution du contexte académique (remplace le module `bootstrap`) :
/// lecture 100% locale du référentiel offline déjà pullé pour Inscription
/// (`ref_academic_years`/`ref_school_level_groups`/`ref_school_levels`),
/// scopée à l'école de l'utilisateur courant (`CurrentUserContext`).
abstract class AcademicYearContextRepository {
  /// Année **courante** + ses cycles/niveaux. Si le référentiel n'est pas
  /// encore en local pour cette école : déclenche un pull en ligne, ou renvoie
  /// [NetworkFailure] hors ligne (pas de repli possible — c'est le gate de
  /// démarrage).
  Future<Either<Failure, AcademicYearContext>> loadCurrentContext();

  /// Année **précédente** + ses cycles/niveaux (RE/PRE). `Right(null)` = pas
  /// d'année antérieure connue (école dans sa première année) — un état
  /// légitime, jamais un échec. Suppose le référentiel déjà résolu par
  /// [loadCurrentContext] (aucun pull déclenché ici).
  Future<Either<Failure, AcademicYearContext?>> loadPreviousContext();

  /// Patch optimiste post-répartition (Classe) : le niveau [schoolLevelId]
  /// vient d'être réparti en classes côté serveur. Écrit directement le
  /// référentiel local ; reconfirmé sans conflit par le prochain pull.
  Future<void> markSchoolLevelSplit(String schoolLevelId);
}
