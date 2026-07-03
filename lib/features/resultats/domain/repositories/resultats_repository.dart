import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_focus.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';

/// Contrat de la feature **résultats par classe** (lecture seule, calcul live).
///
/// Le roster de la recherche « Par élève » réutilise l'entité partagée
/// [ClassroomMember] (feature `classes`) : pas de nouveau type roster.
abstract class ResultatsRepository {
  /// Vue classe (synthèse + table) pour un couple (classe, grande période).
  ///
  /// [seuil] optionnel : `null` ⇒ le backend applique 50 %.
  Future<Either<Failure, ResultatsClasse>> getResultatsClasse(
    String classroomId,
    String periodeScolaireId,
    double? seuil,
  );

  /// Vue focus d'un élève (en-tête, progression, top/bottom, bulletin, synthèse).
  Future<Either<Failure, ResultatFocus>> getResultatFocus(
    String classroomId,
    String periodeScolaireId,
    String studentId,
  );

  /// Recherche roster scopée à la classe (mode « Par élève »).
  ///
  /// [nom] / [postnom] / [prenom] optionnels, combinés en ET côté backend
  /// (chaîne vide traitée comme absente).
  Future<Either<Failure, List<ClassroomMember>>> searchRoster(
    String classroomId,
    String academicYearId,
    String? nom,
    String? postnom,
    String? prenom,
  );

  /// Grandes périodes **d'une classe** (source des `periodeScolaireId`), la
  /// période courante marquée. Retournées déjà triées par `ordre` asc (ne pas
  /// re-trier). Le backend résout l'année × cycle depuis [classroomId].
  Future<Either<Failure, List<PeriodeScolaire>>> getPeriodesScolaires(
    String classroomId,
  );
}
