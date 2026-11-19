import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/outbox_push_access.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_permission_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_event_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/wire/calendar_wire.dart';

/// Type d'agrégat d'outbox des gestes sur les événements du calendrier.
const String kCalendarEventsBatchAggregateType = 'CALENDAR_EVENTS_BATCH';

/// Le plafond d'un lot.
const int kCalendarEventsBatchMaxLines = 200;

/// Une entrée ne fige pas de lignes : elle dit « cette école a des gestes à
/// envoyer ». Les lignes se lisent au départ, donc toujours fraîches.
OutboxEntry calendarEventsOutboxEntry({
  required String schoolId,
  required int createdAt,
}) => OutboxEntry(
  id: '$kCalendarEventsBatchAggregateType:$schoolId',
  aggregateType: kCalendarEventsBatchAggregateType,
  aggregateId: schoolId,
  operation: OutboxOperation.upsert,
  payload: jsonEncode({'schoolId': schoolId}),
  schoolId: schoolId,
  createdAt: createdAt,
);

/// Le résultat d'une ligne du lot (contrat figé le 2026-11-19).
enum CalendarEventOutcome {
  applied,
  superseded,
  rejected;

  static CalendarEventOutcome? tryParse(Object? value) => switch (value) {
    'APPLIED' => applied,
    'SUPERSEDED' => superseded,
    'REJECTED' => rejected,
    _ => null,
  };
}

/// Pousse les gestes en attente et réconcilie **ligne par ligne** :
/// - APPLIED et SUPERSEDED reprennent l'état gagnant du serveur ; SUPERSEDED
///   marque la ligne pour que l'écran prévienne (CAL-R16) ;
/// - REJECTED garde la ligne, en erreur, avec son code (CAL-I19) ;
/// - une ligne sans résultat reste en attente et fait rejouer le lot.
class CalendarEventsOutboxHandler
    implements OutboxWriteAccess, OutboxSyncHandler {
  final Dio _dio;
  final CalendarEventDao _dao;
  final OutboxDao _outbox;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  const CalendarEventsOutboxHandler({
    required Dio dio,
    required CalendarEventDao dao,
    required OutboxDao outbox,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _dio = dio,
       _dao = dao,
       _outbox = outbox,
       _requiredAuth = requiredAuth,
       _now = now;

  @override
  String get aggregateType => kCalendarEventsBatchAggregateType;

  @override
  ModuleAccess? writeAccessFor(OutboxEntry entry) => kCalendarEventPushAccess;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final String schoolId;
    try {
      schoolId = (jsonDecode(entry.payload) as Map)['schoolId'] as String;
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid calendar payload');
    }
    try {
      final lines = await _dao.pending(
        schoolId,
        limit: kCalendarEventsBatchMaxLines,
      );
      if (lines.isEmpty) return const OutboxDispatchResult.acked();
      final Response<Map<String, dynamic>> response;
      try {
        response = await _dio.post<Map<String, dynamic>>(
          AppConstants.syncCalendarEventsPushEndpoint,
          data: {
            'events': [for (final l in lines) CalendarWire.eventToJson(l)],
          },
          options: Options(extra: _requiredAuth),
        );
      } on DioException catch (e) {
        return _classify(e);
      }
      final results = {
        for (final raw in (response.data?['results'] as List?) ?? const [])
          if (raw is Map && raw['id'] is String) raw['id'] as String: raw,
      };
      final nowMs = _now();
      var unresolved = 0;
      for (final line in lines) {
        final result = results[line.element.id];
        final outcome = CalendarEventOutcome.tryParse(result?['outcome']);
        if (result == null || outcome == null) {
          unresolved++;
          continue;
        }
        await _reconcile(
          line.element.id,
          line.clientUpdatedAtMs,
          outcome,
          result,
          schoolId,
          nowMs,
        );
      }
      if (unresolved > 0) {
        return const OutboxDispatchResult.retry(
          'Réponse serveur incomplète — le lot sera rejoué',
        );
      }
      if (await _dao.pendingCount(schoolId) > 0) {
        await _outbox.enqueue(
          calendarEventsOutboxEntry(
            schoolId: schoolId,
            createdAt: math.max(_now(), entry.createdAt + 1),
          ),
        );
      }
      return const OutboxDispatchResult.acked();
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  Future<void> _reconcile(
    String id,
    int pushedAt,
    CalendarEventOutcome outcome,
    Map result,
    String schoolId,
    int nowMs,
  ) async {
    if (outcome == CalendarEventOutcome.rejected) {
      await _dao.markRejected(
        id: id,
        pushedAt: pushedAt,
        code: result['reason'] as String?,
      );
      return;
    }
    PulledEvent? server;
    try {
      server = result['event'] == null
          ? null
          : CalendarWire.eventFromJson(result['event']);
    } catch (_) {
      server = null;
    }
    if (server == null) {
      await _dao.markSynced(id: id, pushedAt: pushedAt);
      return;
    }
    await _dao.applyServerState(
      id: id,
      pushedAt: pushedAt,
      server: server,
      superseded: outcome == CalendarEventOutcome.superseded,
      schoolId: schoolId,
      nowMs: nowMs,
    );
  }

  /// Le réseau, le 5xx, le 401 (la session se reprend) se rejouent ; un refus
  /// de forme ou de droits, non (un 403 de permission est retenu par le moteur
  /// jusqu'au retour du droit, ADR-014 §13.3).
  OutboxDispatchResult _classify(DioException e) {
    final status = e.response?.statusCode;
    final transient =
        status == null ||
        status >= 500 ||
        status == 401 ||
        status == 408 ||
        status == 409 ||
        status == 429;
    final reason = ApiErrorParser.pushFailureReason(e);
    return transient
        ? OutboxDispatchResult.retry(reason)
        : OutboxDispatchResult.failed(reason);
  }
}
