import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, SyncEngine, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/notes_batch_push_models.dart';

/// Type d'agrégat d'outbox du lot de notes (routage → `NotesBatchOutboxHandler`).
const String kNotesBatchAggregateType = 'ACADEMICS_NOTES_BATCH';

/// Une note à enregistrer (entrée de saisie). `pointsObtenus` nul = absent.
class NoteSaveInput {
  final String studentId;
  final String statut;
  final double? pointsObtenus;

  const NoteSaveInput({
    required this.studentId,
    required this.statut,
    this.pointsObtenus,
  });
}

/// Écriture offline-first d'un lot de notes (**régime C**, upsert clé naturelle
/// + LWW). Délègue au datasource l'upsert atomique + le gel du payload de lot
/// **coalescé** (toutes les notes PENDING de l'évaluation, pas seulement celles
/// de cet appel). L'`authorId` est estampillé depuis [CurrentUserContext].
class NotesOfflineRepositoryImpl {
  final AcademicsLocalDataSource _local;
  final IdGenerator _idGenerator;
  final CurrentUserContext? _currentUser;
  final SyncEngine? _syncEngine;
  final Clock _now;

  const NotesOfflineRepositoryImpl({
    required AcademicsLocalDataSource localDataSource,
    required IdGenerator idGenerator,
    CurrentUserContext? currentUser,
    SyncEngine? syncEngine,
    Clock now = systemClock,
  }) : _local = localDataSource,
       _idGenerator = idGenerator,
       _currentUser = currentUser,
       _syncEngine = syncEngine,
       _now = now;

  /// Id d'outbox déterministe **unique par évaluation** (coalescing du lot).
  static String aggregateOutboxId(String evaluationId) =>
      '$kNotesBatchAggregateType:$evaluationId';

  /// Enregistre/corrige un lot de notes d'une évaluation. Renvoie les notes
  /// encore `PENDING_SYNC` (celles gelées dans le payload de push).
  Future<Either<Failure, List<NoteEvaluationRow>>> saveNotes({
    required String evaluationId,
    required List<NoteSaveInput> notes,
  }) async {
    try {
      final nowMs = _now();
      final rows = notes
          .map(
            (n) => NoteEvaluationRow(
              id: _idGenerator.newId(),
              evaluationId: evaluationId,
              studentId: n.studentId,
              pointsObtenus: n.pointsObtenus,
              statut: n.statut,
              updatedAt: nowMs,
            ),
          )
          .toList(growable: false);

      final pending = await _local.upsertNotesWithOutbox(
        evaluationId: evaluationId,
        incoming: rows,
        buildOutboxEntry: (pendingNotes) => OutboxEntry(
          id: aggregateOutboxId(evaluationId),
          aggregateType: kNotesBatchAggregateType,
          aggregateId: evaluationId,
          operation: OutboxOperation.upsert,
          payload: NotesBatchPushRequestModel(
            authorId: _currentUser?.uid,
            evaluationId: evaluationId,
            notes: pendingNotes
                .map(NoteInputModel.fromRow)
                .toList(growable: false),
          ).toJsonString(),
          createdAt: nowMs,
        ),
      );
      // Flush opportuniste : si connecté, le lot part tout de suite ; sinon
      // l'outbox le rejouera au retour online. Sans lui, une saisie faite EN
      // LIGNE attendrait un déclencheur fortuit (reconnexion) pour partir.
      final engine = _syncEngine;
      if (engine != null) unawaited(engine.flush());
      return Right(pending);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
