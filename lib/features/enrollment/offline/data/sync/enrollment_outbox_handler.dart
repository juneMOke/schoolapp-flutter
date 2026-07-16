import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ack_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

/// Handler d'outbox de l'agrégat ENROLLMENT (contrat `openapi_enrollment_sync`).
///
/// Décode le payload figé → reconstruit la commande typée → POST
/// `/api/v1/sync/enrollments` (agrégat) → route la réponse par statut HTTP :
///  - 201/200 : applique le remap transactionnel (matricule/email, parent
///    provisoire→canonique, doc PROV→DEFINITIVE, SYNCED) → `acked` ;
///  - 4xx client-terminal (400/403/404/409/422…) : rejet définitif que rejouer
///    ne corrigerait pas → marque SYNC_ERROR local → `failed` (non rejoué) ;
///  - réseau / timeout / 5xx / 401 / 408 / 429 : transitoire → `retry` (backoff,
///    idempotent sur enrollment.id).
class EnrollmentOutboxHandler implements OutboxSyncHandler {
  final EnrollmentSyncApi _api;
  final EnrollmentAckDao _dao;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const EnrollmentOutboxHandler({
    required EnrollmentSyncApi api,
    required EnrollmentAckDao dao,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => 'ENROLLMENT';

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final EnrollmentCommand command;
    try {
      final map = jsonDecode(entry.payload) as Map<String, dynamic>;
      command = EnrollmentCommand.fromJson(map);
    } catch (e) {
      // Payload corrompu : erreur définitive (non rejouable).
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }

    try {
      final response = await _api.submit(
        _extras,
        EnrollmentAggregateRequest(command),
      );
      // 201/200 : commit (ou rejeu idempotent) → remap canonique local.
      await _dao.applyEnrollmentAck(
        response,
        enrollmentId: entry.aggregateId,
        nowMs: _now(),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 4xx client-terminal (validation 422, payload 400, permission 403,
      // introuvable 404, conflit d'idempotence divergent 409…) : rejouer ne
      // corrigerait rien et gaspillerait le backoff jusqu'au dead-letter
      // générique → SYNC_ERROR immédiat (non rejoué), avec le motif serveur s'il
      // est présent. Restent TRANSITOIRES (→ retry) : 401 (ré-auth), 408
      // (timeout requête), 429 (rate-limit), plus tout 5xx / réseau / timeout.
      if (status != null &&
          status >= 400 &&
          status < 500 &&
          status != 401 &&
          status != 408 &&
          status != 429) {
        final message = _validationMessage(e) ?? 'Rejet serveur ($status)';
        await _dao.markEnrollmentSyncError(
          entry.aggregateId,
          message,
          nowMs: _now(),
        );
        return OutboxDispatchResult.failed(message);
      }
      // Réseau / timeout / 5xx / 401 / 408 / 429 : transitoire → retry (idempotent).
      return OutboxDispatchResult.retry(e.message ?? e.toString());
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  /// Extrait le message d'un corps d'erreur `Error {code, message, details}`.
  String? _validationMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}
