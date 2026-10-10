import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_outbox.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_sync_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_push.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_sync_api.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_sync_dao.dart'
    show ChapitreServerState;
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_failure.dart';

/// Ce que le serveur sait d'un chapitre, vu de la tablette.
typedef ChapitreStateReader = Future<ChapitreServerState> Function(String id);

/// Handler de l'agrégat `JOURNAL_ENTRY` : la saisie d'une séance.
///
/// - chapitre cité **pas encore accusé** : l'entrée l'attend (`blocked`), sans
///   réseau — le 409 `CHAPITRE_NOT_YET_SYNCED` n'est que le filet d'une course ;
/// - chapitre **parti** de la tablette : l'entrée part détachée, comme le
///   serveur l'aurait retenue ;
/// - accusé : l'entrée retenue s'applique (la sienne si la nôtre était
///   dépassée) ;
/// - 403 `COURS_NOT_OWNED` : le cours quitte la tablette, le geste avec lui ;
/// - autre refus (400, 422) : « à corriger », sauf si une saisie plus récente
///   l'a remplacée pendant le vol.
class JournalOutboxHandler implements OutboxSyncHandler {
  final JournalSyncApi _api;
  final JournalSyncDao _dao;
  final ChapitreStateReader _chapitreState;
  final CoursEvictor _evictCours;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const JournalOutboxHandler({
    required JournalSyncApi api,
    required JournalSyncDao dao,
    required ChapitreStateReader chapitreState,
    required CoursEvictor evictCours,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _chapitreState = chapitreState,
       _evictCours = evictCours,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => JournalOutbox.type;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    JournalEntryPayload? payload;
    try {
      payload = JournalEntryPayload.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (payload == null) {
      return const OutboxDispatchResult.failed('Payload de journal incomplet');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;

    final chapitreId = payload.chapitreId;
    if (chapitreId != null) {
      switch (await _chapitreState(chapitreId)) {
        case ChapitreServerState.unknown:
          return const OutboxDispatchResult.blocked(
            'Chapitre pas encore accusé',
          );
        case ChapitreServerState.gone:
          payload = payload.detached();
        case ChapitreServerState.known:
          break;
      }
    }

    try {
      final ack = await _api.saveEntry(
        _extras,
        outboxEnvelope('entry', payload.entry, entry),
      );
      await _dao.applyAck(
        ack,
        sentClientUpdatedAt: payload.clientUpdatedAt,
        nowMs: _now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      return _onFailure(entry, payload, ProgrammePushFailure.of(e));
    } catch (e) {
      // Échec LOCAL après un envoi peut-être accusé : le rejeu est idempotent.
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  Future<OutboxDispatchResult> _onFailure(
    OutboxEntry entry,
    JournalEntryPayload payload,
    ProgrammePushFailure failure,
  ) async {
    if (failure.coursNotOwned) {
      await _evictCours(payload.coursId);
      return const OutboxDispatchResult.acked();
    }
    if (failure.awaitsChapitre) {
      return OutboxDispatchResult.blocked(failure.reason);
    }
    if (failure.isTransient) return OutboxDispatchResult.retry(failure.reason);
    final marked = await _dao.markRejected(
      payload.entryId,
      sentClientUpdatedAt: payload.clientUpdatedAt,
      code: failure.storedCode,
      nowMs: _now(),
    );
    // Non marquée : soit une saisie plus récente a remplacé l'entrée (elle
    // repartira), soit une descente a remplacé la ligne — le refus est alors
    // définitif.
    if (!marked && await _dao.entryReplaced(payload.entryId, entry.createdAt)) {
      return OutboxDispatchResult.retry(failure.reason);
    }
    return OutboxDispatchResult.failed(failure.reason);
  }
}
