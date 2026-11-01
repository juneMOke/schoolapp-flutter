import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_sync_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_write_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_push_models.dart';

/// Type d'agrégat d'outbox de la saisie des notes.
const String kCotesBatchAggregateType = 'ACADEMICS_COTES_BATCH';

/// Le plafond du contrat : 200 lignes par lot.
const int kCotesBatchMaxLines = 200;

/// Une entrée d'outbox ne fige pas de lignes : elle dit « cette classe, cet
/// auteur a des cotes à envoyer ». Les lignes se lisent au départ, donc toujours
/// fraîches, et par tranches de [kCotesBatchMaxLines].
OutboxEntry cotesOutboxEntry({
  required String classroomId,
  required String authorId,
  required int createdAt,
}) => OutboxEntry(
  id: '$kCotesBatchAggregateType:$classroomId:$authorId',
  aggregateType: kCotesBatchAggregateType,
  aggregateId: classroomId,
  operation: OutboxOperation.upsert,
  payload: jsonEncode({
    if (authorId.isNotEmpty) 'authorId': authorId,
    'classroomId': classroomId,
  }),
  createdAt: createdAt,
);

/// Pousse les cotes en attente d'une classe et réconcilie **ligne par ligne**.
///
/// `APPLIED` et `SUPERSEDED` reprennent l'état du serveur ; `REJECTED` garde la
/// valeur à l'écran, signalée : le serveur n'en conserve rien. Une ligne sans
/// résultat reste en attente et fait rejouer le lot. S'il reste des lignes, la
/// tranche suivante est ré-enfilée : l'accusé de l'entrée d'origine, gardé sur
/// son `created_at`, ne la retire alors pas.
class CotesBatchOutboxHandler implements OutboxSyncHandler {
  final CotesSyncApi _api;
  final CotesWriteLocalDataSource _local;
  final OutboxDao _outbox;
  final Map<String, dynamic> _requiredAuth;
  final Clock _now;

  const CotesBatchOutboxHandler({
    required CotesSyncApi api,
    required CotesWriteLocalDataSource localDataSource,
    required OutboxDao outbox,
    required Map<String, dynamic> requiredAuth,
    Clock now = systemClock,
  }) : _api = api,
       _local = localDataSource,
       _outbox = outbox,
       _requiredAuth = requiredAuth,
       _now = now;

  @override
  String get aggregateType => kCotesBatchAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final String classroomId;
    final String authorId;
    try {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      classroomId = payload['classroomId'] as String;
      authorId = payload['authorId'] as String? ?? '';
    } catch (_) {
      return const OutboxDispatchResult.failed('Invalid cotes payload');
    }
    try {
      final lines = await _local.pendingLines(
        classroomId: classroomId,
        authorId: authorId,
        limit: kCotesBatchMaxLines,
      );
      if (lines.isEmpty) return const OutboxDispatchResult.acked();

      final CotesPushResponse response;
      try {
        response = await _api.submit(
          _requiredAuth,
          CotesPushRequest(
            authorId: authorId.isEmpty ? null : authorId,
            cotes: lines,
          ),
        );
      } on DioException catch (e) {
        return _classify(e);
      }

      final unresolved = await _reconcile(lines, response);
      if (unresolved > 0) {
        return const OutboxDispatchResult.retry(
          'Réponse serveur incomplète — le lot sera rejoué',
        );
      }
      final remaining = await _local.pendingCount(
        classroomId: classroomId,
        authorId: authorId,
      );
      if (remaining > 0) {
        await _outbox.enqueue(
          cotesOutboxEntry(
            classroomId: classroomId,
            authorId: authorId,
            createdAt: math.max(_now(), entry.createdAt + 1),
          ),
        );
      }
      return const OutboxDispatchResult.acked();
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  /// Un refus de droits ou de forme ne se rejouera pas à l'identique ; le
  /// réseau, le 5xx et le 401 (la session se reprend) oui.
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

  /// Rend le nombre de lignes envoyées restées sans résultat.
  Future<int> _reconcile(
    List<CoteLineDto> lines,
    CotesPushResponse response,
  ) async {
    final nowMs = _now();
    final byKey = {
      for (final result in response.results)
        '${result.studentId}|${result.coursId}|${result.colonneId}': result,
    };
    var unresolved = 0;
    for (final line in lines) {
      final key = line.key;
      final result = byKey['${key.studentId}|${key.coursId}|${key.colonneId}'];
      if (result == null) {
        unresolved++;
        continue;
      }
      if (result.outcome == CoteOutcome.rejected) {
        await _local.markRejected(
          key: key,
          pushedAt: line.updatedAtMs,
          reason: result.reason,
        );
      } else {
        await _local.applyServerValue(
          key: key,
          pushedAt: line.updatedAtMs,
          valeur: result.valeur,
          serverUpdatedAtMs: result.updatedAtMs,
          superseded: result.outcome == CoteOutcome.superseded,
          nowMs: nowMs,
        );
      }
    }
    return unresolved;
  }
}
