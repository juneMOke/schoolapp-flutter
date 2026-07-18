import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_sync_api.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_offline_repository_impl.dart'
    show kClassroomTransferAggregateType;

/// Handler d'outbox de l'agrégat CLASSROOM_TRANSFER (CF4).
///
/// `POST /api/v1/sync/classroom-transfers` (idempotent sur `transfer.id`) → ACK :
/// repositionne le miroir + compteurs des 2 classes + scelle SYNCED en une
/// transaction (passage de témoin atomique). **Aucune garde `blocked`** : le
/// roster gate par construction (`depends_on` toujours NULL, ADR-007) — un élève
/// transférable vient forcément d'une répartition serveur déjà synchronisée.
///
/// **Classification des échecs HTTP** ([_classifyDioError]) : transitoire
/// (`retry`, rejoué avec backoff) pour le transport, les 5xx et 401/408/409/429 ;
/// déterministe (`failed`, basculé SYNC_ERROR) pour les autres 4xx — dont le
/// `422 LEVEL_MISMATCH`. Le POST étant idempotent, un 4xx signifie que le serveur
/// n'a rien enregistré : rejouer jusqu'au poison ne ferait que retarder le rejet.
class ClassroomTransferOutboxHandler implements OutboxSyncHandler {
  final ClassroomTransferSyncApi _api;
  final ClassroomLocalDataSource _localDataSource;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const ClassroomTransferOutboxHandler({
    required ClassroomTransferSyncApi api,
    required ClassroomLocalDataSource localDataSource,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _localDataSource = localDataSource,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => kClassroomTransferAggregateType;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(entry.payload) as Map<String, dynamic>;
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }

    try {
      final ack = await _api.submitTransfer(_extras, body);
      await _localDataSource.applyTransferAck(ack, nowMs: _now());
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      return _classifyDioError(e);
    } catch (e) {
      // Échec LOCAL (ex. `applyTransferAck`) après un POST possiblement acquitté :
      // retry-biaisé, le POST est idempotent (rejeu = 200 canonique). La
      // composition à la lecture montre déjà l'élève dans la destination.
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  /// Statuts HTTP transitoires hormis les 5xx : jeton expiré (401), timeout
  /// (408), conflit à rejouer (409), débit dépassé (429).
  static const Set<int> _transientStatuses = {401, 408, 409, 429};

  /// Transitoire (`retry`) pour le transport, les 5xx et [_transientStatuses] ;
  /// déterministe (`failed`) pour les autres 4xx (dont `422 LEVEL_MISMATCH`).
  OutboxDispatchResult _classifyDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == null ||
        status >= 500 ||
        _transientStatuses.contains(status)) {
      return OutboxDispatchResult.retry(_dioReason(e, status));
    }
    return OutboxDispatchResult.failed(_dioReason(e, status));
  }

  String _dioReason(DioException e, int? status) {
    final where = status != null ? 'HTTP $status' : 'réseau';
    final detail = e.message ?? e.error?.toString();
    return detail == null || detail.isEmpty ? where : '$where — $detail';
  }
}
