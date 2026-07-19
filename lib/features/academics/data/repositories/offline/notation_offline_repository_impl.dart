import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notes_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/notation_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';

/// Implémentation **offline-first** de [NotationRepository].
///
/// Lecture 100 % locale : la grille de notes est **composée** au read = le
/// **roster** de la classe du cours (`ref_classroom_members`, module Classe)
/// surchargé par les **notes locales** (`note_evaluation`). Un élève sans note
/// reste `pointsObtenus`/`statut` nuls (« pas encore saisi »). Écriture déléguée
/// au [NotesOfflineRepositoryImpl] (régime C, upsert + outbox).
class NotationOfflineRepositoryImpl implements NotationRepository {
  final AcademicsLocalDataSource _local;
  final AcademicsRefLocalDataSource _refLocal;
  final ClassroomLocalDataSource _rosterDataSource;
  final NotesOfflineRepositoryImpl _notesRepository;

  const NotationOfflineRepositoryImpl({
    required AcademicsLocalDataSource localDataSource,
    required AcademicsRefLocalDataSource refLocalDataSource,
    required ClassroomLocalDataSource rosterDataSource,
    required NotesOfflineRepositoryImpl notesRepository,
  }) : _local = localDataSource,
       _refLocal = refLocalDataSource,
       _rosterDataSource = rosterDataSource,
       _notesRepository = notesRepository;

  @override
  Future<Either<Failure, List<NoteEleve>>> getNotesEleves(
    String evaluationId,
  ) async {
    try {
      final evaluation = await _local.getEvaluation(evaluationId);
      if (evaluation == null) {
        return const Left(NotFoundFailure('Évaluation introuvable localement'));
      }
      final cours = await _refLocal.getCours(evaluation.coursId);
      if (cours == null) {
        return const Left(NotFoundFailure('Cours introuvable localement'));
      }

      final roster = await _rosterDataSource.getRoster(cours.classroomId);
      final notes = await _local.getNotesForEvaluation(evaluationId);
      final noteByStudent = {for (final n in notes) n.studentId: n};

      final eleves = roster
          .where((m) => m.status.toUpperCase() == 'ACTIVE')
          .map((m) {
            final note = noteByStudent[m.studentId];
            return NoteEleve(
              studentId: m.studentId,
              firstName: m.studentFirstName,
              lastName: m.studentLastName,
              middleName: m.studentMiddleName,
              pointsObtenus: note?.pointsObtenus,
              statut: note == null
                  ? null
                  : StatutNoteX.fromApiValue(note.statut),
            );
          })
          .toList(growable: false);

      return Right(eleves);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEvaluation>> saisirNote(
    String evaluationId,
    SaisirNoteRequest request,
  ) async {
    final result = await _notesRepository.saveNotes(
      evaluationId: evaluationId,
      notes: [
        NoteSaveInput(
          studentId: request.studentId,
          statut: request.statut.toApiValue(),
          pointsObtenus: request.pointsObtenus,
        ),
      ],
    );
    return result.fold(Left.new, (pending) {
      NoteEvaluationRow? row;
      for (final n in pending) {
        if (n.studentId == request.studentId) {
          row = n;
          break;
        }
      }
      // `row` est normalement présente (l'upsert à `now()` gagne toujours le
      // LWW). Repli défensif sur la requête si le lot ne la porte pas.
      return Right(
        NoteEvaluation(
          id: row?.id ?? '',
          evaluationId: evaluationId,
          studentId: request.studentId,
          pointsObtenus: row?.pointsObtenus ?? request.pointsObtenus,
          statut: row == null
              ? request.statut
              : StatutNoteX.fromApiValue(row.statut),
        ),
      );
    });
  }
}
