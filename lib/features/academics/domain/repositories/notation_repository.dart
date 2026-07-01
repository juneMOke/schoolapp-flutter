import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';

/// Contrat de saisie des notes d'une évaluation.
///
/// Flux mixte lecture + écriture : [getNotesEleves] peuple la grille (une ligne
/// par élève), [saisirNote] enregistre/rattrape la note d'un élève (upsert
/// idempotent sur `(evaluationId, studentId)`).
abstract class NotationRepository {
  /// Charge la grille : chaque élève de la classe du cours + sa note actuelle
  /// pour l'évaluation [evaluationId] (`pointsObtenus`/`statut` nuls tant
  /// qu'aucune saisie).
  Future<Either<Failure, List<NoteEleve>>> getNotesEleves(String evaluationId);

  /// Saisit ou met à jour (rattrapage) la note d'un élève pour [evaluationId].
  ///
  /// Idempotent : rejouable sans créer de doublon. [request] garantit la
  /// cohérence statut/points par construction.
  Future<Either<Failure, NoteEvaluation>> saisirNote(
    String evaluationId,
    SaisirNoteRequest request,
  );
}
