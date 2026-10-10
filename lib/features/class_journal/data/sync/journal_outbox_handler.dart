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

/// Le serveur a-t-il refusé la fiche de ce chapitre ?
typedef ChapitreRejectedReader = Future<bool> Function(String id);

/// Le code rangé sur une séance qui cite un chapitre refusé.
const String kJournalChapitreRejectedCode = 'CHAPITRE_REJECTED';

/// Handler de l'agrégat `JOURNAL_ENTRY` : la saisie d'une séance.
///
/// - chapitre cité **pas encore accusé** : l'entrée l'attend (`blocked`), sans
///   réseau — le 409 `CHAPITRE_NOT_YET_SYNCED` n'est que le filet d'une course ;
///   sa fiche **refusée** : l'entrée est « à corriger », elle attendrait en vain ;
/// - chapitre **absent** de la tablette (supprimé, ou pas encore descendu) :
///   l'entrée part telle quelle — le serveur détache un chapitre supprimé. S'il
///   ne l'a jamais vu (créé puis supprimé ici avant tout accusé), son 409
///   relance l'envoi détaché ;
/// - 404 : le cours n'existe plus au serveur — l'entrée quitte la tablette ;
/// - accusé : l'entrée retenue s'applique (la sienne si la nôtre était
///   dépassée) ;
/// - 403 `COURS_NOT_OWNED` : le cours quitte la tablette, le geste avec lui ;
/// - autre refus (400, 422) : « à corriger », sauf si une saisie plus récente
///   l'a remplacée pendant le vol.
class JournalOutboxHandler implements OutboxSyncHandler {
  final JournalSyncApi _api;
  final JournalSyncDao _dao;
  final ChapitreStateReader _chapitreState;
  final ChapitreRejectedReader _chapitreRejected;
  final CoursEvictor _evictCours;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const JournalOutboxHandler({
    required JournalSyncApi api,
    required JournalSyncDao dao,
    required ChapitreStateReader chapitreState,
    required ChapitreRejectedReader chapitreRejected,
    required CoursEvictor evictCours,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _chapitreState = chapitreState,
       _chapitreRejected = chapitreRejected,
       _evictCours = evictCours,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => JournalOutbox.type;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final JournalEntryPayload? payload;
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
    var chapitreAbsent = false;
    if (chapitreId != null) {
      switch (await _chapitreState(chapitreId)) {
        case ChapitreServerState.unknown:
          if (await _chapitreRejected(chapitreId)) {
            return _reject(
              entry,
              payload,
              code: kJournalChapitreRejectedCode,
              reason: 'Chapitre refusé',
            );
          }
          return const OutboxDispatchResult.blocked(
            'Chapitre pas encore accusé',
          );
        case ChapitreServerState.gone:
          chapitreAbsent = true;
        case ChapitreServerState.known:
          break;
      }
    }
    return _send(entry, payload, retryDetached: chapitreAbsent);
  }

  Future<OutboxDispatchResult> _send(
    OutboxEntry entry,
    JournalEntryPayload payload, {
    required bool retryDetached,
  }) async {
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
      final failure = ProgrammePushFailure.of(e);
      if (failure.awaitsChapitre && retryDetached) {
        return _send(entry, payload.detached(), retryDetached: false);
      }
      return _onFailure(entry, payload, failure);
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
    if (failure.status == 404) {
      await _dao.remove(payload.entryId);
      return const OutboxDispatchResult.acked();
    }
    if (failure.isTransient) return OutboxDispatchResult.retry(failure.reason);
    return _reject(
      entry,
      payload,
      code: failure.storedCode,
      reason: failure.reason,
    );
  }

  /// « À corriger », sauf si une saisie plus récente l'a remplacée pendant le
  /// vol (elle repartira).
  Future<OutboxDispatchResult> _reject(
    OutboxEntry entry,
    JournalEntryPayload payload, {
    required String code,
    required String reason,
  }) async {
    final marked = await _dao.markRejected(
      payload.entryId,
      sentClientUpdatedAt: payload.clientUpdatedAt,
      code: code,
      nowMs: _now(),
    );
    // Non marquée : soit une saisie plus récente a remplacé l'entrée (elle
    // repartira), soit une descente a remplacé la ligne — le refus est alors
    // définitif.
    if (!marked && await _dao.entryReplaced(payload.entryId, entry.createdAt)) {
      return OutboxDispatchResult.retry(reason);
    }
    return OutboxDispatchResult.failed(reason);
  }
}
