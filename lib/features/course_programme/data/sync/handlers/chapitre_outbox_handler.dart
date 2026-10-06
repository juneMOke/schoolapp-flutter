import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox_writer.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_sync_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_failure.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_sync_api.dart';

/// Handler de l'agrégat `CHAPITRE` : la fiche d'un chapitre, ou sa
/// suppression.
///
/// - **fiche** : l'accusé porte la fiche retenue ; sur « ignorée » (la nôtre
///   était plus ancienne), la tablette l'applique au lieu de marquer sa ligne
///   synchronisée avec des valeurs périmées. 410 : supprimé ailleurs, la ligne
///   part. Un refus déterministe la marque « à corriger », sauf si une saisie
///   plus récente l'a remplacée pendant le vol.
/// - **suppression** : rejouable ; accusée (ou déjà absente), le chapitre
///   quitte la tablette avec ses enfants.
/// - 403 `COURS_NOT_OWNED` : le cours quitte la tablette, le geste avec lui.
class ChapitreOutboxHandler implements OutboxSyncHandler {
  final ProgrammeSyncApi _api;
  final ProgrammeSyncDao _dao;
  final CoursEvictor _evictCours;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const ChapitreOutboxHandler({
    required ProgrammeSyncApi api,
    required ProgrammeSyncDao dao,
    required CoursEvictor evictCours,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _evictCours = evictCours,
       _currentUser = currentUser,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => ProgrammeOutbox.chapitreType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final ChapitreFichePayload? payload;
    try {
      payload = ChapitreFichePayload.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (payload == null) {
      return const OutboxDispatchResult.failed('Payload de chapitre incomplet');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;

    try {
      switch (payload.op) {
        case ProgrammePushOp.save:
          final ack = await _api.saveChapitre(
            _extras,
            outboxEnvelope('chapitre', payload.fiche, entry),
          );
          await _dao.applyFicheAck(
            ack,
            sentClientUpdatedAt: payload.clientUpdatedAt,
            nowMs: _now(),
          );
        case ProgrammePushOp.delete:
          await _api.deleteChapitre(
            _extras,
            payload.chapitreId,
            outboxAuthorOf(entry),
          );
          await _dao.removeChapitre(payload.chapitreId);
      }
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
    ChapitreFichePayload payload,
    ProgrammePushFailure failure,
  ) async {
    if (failure.coursNotOwned) {
      await _evictCours(payload.coursId);
      return const OutboxDispatchResult.acked();
    }
    final deleting = payload.op == ProgrammePushOp.delete;
    if (deleting ? failure.isGoneForDelete : failure.isGone) {
      await _dao.removeChapitre(payload.chapitreId);
      return const OutboxDispatchResult.acked();
    }
    if (failure.isTransient) return OutboxDispatchResult.retry(failure.reason);
    if (deleting) {
      await _dao.restoreChapitre(
        payload.chapitreId,
        failure.storedCode,
        _now(),
      );
      return OutboxDispatchResult.failed(failure.reason);
    }
    final marked = await _dao.markChapitreRejected(
      payload.chapitreId,
      sentClientUpdatedAt: payload.clientUpdatedAt,
      code: failure.storedCode,
      nowMs: _now(),
    );
    // Non marquée : soit une saisie plus récente a remplacé l'entrée (elle
    // repartira), soit une descente a remplacé la ligne — le refus est alors
    // définitif, le rejouer ne ferait que monter jusqu'au poison.
    if (!marked && await _dao.entryReplaced(entry.id, entry.createdAt)) {
      return OutboxDispatchResult.retry(failure.reason);
    }
    return OutboxDispatchResult.failed(failure.reason);
  }
}
