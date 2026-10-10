import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/handlers/chapitre_child_outbox_handler.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_sync_api.dart';

/// Handler de l'agrégat `CHAPITRE_NOTE` : ajout ou suppression d'une note de
/// séance (cf. [ChapitreChildOutboxHandler]).
class ChapitreNoteOutboxHandler
    extends ChapitreChildOutboxHandler<ChapitreNotePayload> {
  final ProgrammeSyncApi _api;

  ChapitreNoteOutboxHandler({
    required ProgrammeSyncApi api,
    required super.dao,
    required super.evictCours,
    required super.currentUser,
    required super.extras,
    super.now,
  }) : _api = api;

  @override
  String get aggregateType => ProgrammeOutbox.noteType;

  @override
  String get table => ProgrammeTables.note;

  @override
  ChapitreNotePayload? parse(Object? json) =>
      ChapitreNotePayload.tryParse(json);

  @override
  ChildGesture gestureOf(ChapitreNotePayload payload) => ChildGesture(
    op: payload.op,
    id: payload.id,
    chapitreId: payload.chapitreId,
  );

  @override
  Future<OutboxDispatchResult?> sendSave(
    ChapitreNotePayload payload,
    OutboxEntry entry,
  ) async {
    await _api.addNote(extras, outboxEnvelope('note', payload.toBody(), entry));
    return null;
  }

  @override
  Future<void> sendDelete(ChapitreNotePayload payload, OutboxEntry entry) =>
      _api.deleteNote(extras, payload.id, outboxAuthorOf(entry));
}
