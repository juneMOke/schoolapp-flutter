import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/outbox_push_access.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_permission_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_draft_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_wire.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Type d'agrégat d'outbox des gestes de brouillon d'emploi du temps.
const String kTimetableDraftBatchAggregateType = 'SCHEDULE_DRAFT_BATCH';

/// Une entrée par école : « des gestes de brouillon attendent ». Les gestes se
/// lisent au départ, toujours frais, dans l'ordre commencer → cases → abandon.
OutboxEntry timetableDraftOutboxEntry({
  required String schoolId,
  required int createdAt,
}) => OutboxEntry(
  id: '$kTimetableDraftBatchAggregateType:$schoolId',
  aggregateType: kTimetableDraftBatchAggregateType,
  aggregateId: schoolId,
  operation: OutboxOperation.upsert,
  payload: jsonEncode({'schoolId': schoolId}),
  schoolId: schoolId,
  createdAt: createdAt,
);

/// Pousse les gestes de brouillon (`POST /sync/schedule/draft-cells`) et
/// réconcilie **geste par geste** : APPLIED et SUPERSEDED reprennent l'état du
/// serveur (une case en conflit est APPLIED : elle bloque seulement la
/// publication), REJECTED garde son code (TIMETABLE_DRAFT_ENDED…). Un geste
/// sans résultat fait rejouer le lot.
class TimetableDraftOutboxHandler
    implements OutboxWriteAccess, OutboxSyncHandler {
  final Dio _dio;
  final TimetableDraftDao _dao;
  final OutboxDao _outbox;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  const TimetableDraftOutboxHandler({
    required Dio dio,
    required TimetableDraftDao dao,
    required OutboxDao outbox,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _dio = dio,
       _dao = dao,
       _outbox = outbox,
       _requiredAuth = requiredAuth,
       _now = now;

  @override
  String get aggregateType => kTimetableDraftBatchAggregateType;

  @override
  ModuleAccess? writeAccessFor(OutboxEntry entry) => kScheduleWritePushAccess;

  static Map<String, dynamic> _json(DraftGesture g) => switch (g) {
    StartGesture() => {
      'kind': 'START',
      'draftId': g.draftId,
      'classroomId': g.classroomId,
      'clientUpdatedAt': EpochIsoHelper.toIso(g.clock),
    },
    AbandonGesture() => {
      'kind': 'ABANDON',
      'draftId': g.draftId,
      'classroomId': g.classroomId,
      'clientUpdatedAt': EpochIsoHelper.toIso(g.clock),
    },
    CellGesture(:final cell) => {
      'kind': 'CELL',
      'draftId': g.draftId,
      'classroomId': g.classroomId,
      'day': cell.day.wire,
      'slotId': cell.slotId,
      'coursId': cell.coursId,
      'clientUpdatedAt': EpochIsoHelper.toIso(g.clock),
    },
  };

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final String schoolId;
    try {
      schoolId = (jsonDecode(entry.payload) as Map)['schoolId'] as String;
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid timetable payload');
    }
    try {
      final gestures = await _dao.pending();
      if (gestures.isEmpty) return const OutboxDispatchResult.acked();
      final Response<Map<String, dynamic>> response;
      try {
        response = await _dio.post<Map<String, dynamic>>(
          AppConstants.syncScheduleDraftCellsEndpoint,
          data: {
            'gestures': [for (final g in gestures) _json(g)],
          },
          options: Options(extra: _requiredAuth),
        );
      } on DioException catch (e) {
        return _classify(e);
      }
      final results = {
        for (final raw in (response.data?['results'] as List?) ?? const [])
          if (raw is Map && raw['key'] is String) raw['key'] as String: raw,
      };
      final nowMs = _now();
      var unresolved = 0;
      // Les cases d'abord : un START accusé renomme le brouillon (alias, A9)
      // et déplacerait les lignes que les cases doivent retrouver.
      final ordered = [
        ...gestures.where((g) => g is! StartGesture),
        ...gestures.whereType<StartGesture>(),
      ];
      for (final g in ordered) {
        final result = results[g.key];
        final outcome = result?['outcome'];
        if (result == null || outcome is! String) {
          unresolved++;
          continue;
        }
        await _reconcile(g, outcome, result, nowMs);
        // Chaque résultat porte l'en-tête à jour : sa révision est celle que
        // la publication devra présenter (la révision monte à chaque geste).
        final timetable = result['timetable'];
        if (timetable is Map && timetable['revision'] is int) {
          await _dao.noteRevision(g.classroomId, timetable['revision'] as int);
        }
      }
      if (unresolved > 0) {
        return const OutboxDispatchResult.retry(
          'Réponse serveur incomplète — le lot sera rejoué',
        );
      }
      if ((await _dao.pending()).isNotEmpty) {
        await _outbox.enqueue(
          timetableDraftOutboxEntry(
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
    DraftGesture g,
    String outcome,
    Map result,
    int nowMs,
  ) async {
    if (outcome == 'REJECTED') {
      await _dao.gestureRejected(g, result['reason'] as String?);
      return;
    }
    switch (g) {
      case StartGesture():
        final timetable = result['timetable'];
        await _dao.startApplied(
          g,
          canonicalDraftId: timetable is Map
              ? timetable['draftId'] as String?
              : null,
        );
      case AbandonGesture():
        await _dao.abandonApplied(g);
      case CellGesture():
        PulledTimetableRow? server;
        try {
          server = result['cell'] == null
              ? null
              : TimetableWire.cell(result['cell']);
        } catch (_) {
          server = null;
        }
        await _dao.cellApplied(
          g,
          server: server?.value,
          serverUpdatedAtMs: server?.serverUpdatedAtMs,
          superseded: outcome == 'SUPERSEDED',
          nowMs: nowMs,
        );
    }
  }

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
