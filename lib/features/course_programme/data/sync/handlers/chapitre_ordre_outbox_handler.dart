import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_school_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_sync_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_failure.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_sync_api.dart';

/// Handler de l'agrégat `CHAPITRE_ORDRE` : l'ordre des chapitres d'un cours,
/// liste complète.
///
/// Attend (`blocked`) qu'aucun chapitre cité ne soit inconnu du serveur : il
/// répondrait 409 `CHAPITRE_NOT_YET_SYNCED`, jamais un id ignoré en silence.
/// L'accusé porte l'ordre retenu (chapitres créés ailleurs compris), appliqué
/// sauf si un nouvel ordre attend déjà.
class ChapitreOrdreOutboxHandler implements OutboxSyncHandler {
  final ProgrammeSyncApi _api;
  final ProgrammeSyncDao _dao;
  final CoursEvictor _evictCours;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const ChapitreOrdreOutboxHandler({
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
  String get aggregateType => ProgrammeOutbox.ordreType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final ChapitreOrdrePayload? payload;
    try {
      payload = ChapitreOrdrePayload.tryParse(jsonDecode(entry.payload));
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }
    if (payload == null) {
      return const OutboxDispatchResult.failed('Payload d\'ordre incomplet');
    }
    final hold = outboxForeignSchoolHold(entry, _currentUser.schoolId);
    if (hold != null) return hold;
    if (await _dao.anyUnknown(payload.chapitreIds)) {
      return const OutboxDispatchResult.blocked('Chapitre pas encore accusé');
    }

    try {
      final ack = await _api.reorderChapitres(
        _extras,
        payload.coursId,
        withOutboxAuthor(payload.toBody(), entry),
      );
      await _dao.applyOrdreAck(
        payload.coursId,
        ack.chapitreIds,
        sentCreatedAt: entry.createdAt,
        nowMs: _now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final failure = ProgrammePushFailure.of(e);
      if (failure.coursNotOwned) {
        await _evictCours(payload.coursId);
        return const OutboxDispatchResult.acked();
      }
      if (failure.awaitsChapitre) {
        return OutboxDispatchResult.blocked(failure.reason);
      }
      if (failure.isTransient) {
        return OutboxDispatchResult.retry(failure.reason);
      }
      return OutboxDispatchResult.failed(failure.reason);
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
