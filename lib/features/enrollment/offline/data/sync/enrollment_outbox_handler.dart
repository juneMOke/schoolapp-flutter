import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

/// Handler d'outbox de l'agrégat ENROLLMENT (F-Lot 5).
///
/// Décode le payload figé → reconstruit la commande typée → POST
/// `/api/v1/sync/enrollments` → route l'ACK :
///  - COMMITTED : applique le remap transactionnel (matricule/email, parent
///    provisoire→canonique, doc PROV→DEFINITIVE, SYNCED) → `acked` ;
///  - VALIDATION_ERROR : marque SYNC_ERROR local → `failed` (non rejoué) ;
///  - réseau / 5xx / exception : `retry` (backoff, idempotent sur enrollment.id).
class EnrollmentOutboxHandler implements OutboxSyncHandler {
  final EnrollmentSyncApi _api;
  final EnrollmentLocalDao _dao;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const EnrollmentOutboxHandler({
    required EnrollmentSyncApi api,
    required EnrollmentLocalDao dao,
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
      final result = await _api.commit(
        _extras,
        EnrollmentCommitBatch([command]),
      );
      final ack = result.forClientEnrollmentId(entry.aggregateId);
      if (ack == null) {
        // Le serveur n'a pas renvoyé d'ACK pour cet item : on rejoue.
        return const OutboxDispatchResult.retry('ACK absent pour l\'agrégat');
      }

      if (ack.isCommitted) {
        await _dao.applyEnrollmentAck(ack, nowMs: _now());
        return const OutboxDispatchResult.acked();
      }

      // VALIDATION_ERROR : on reflète le rejet en local puis on échoue l'entrée.
      await _dao.applyEnrollmentAck(ack, nowMs: _now());
      return OutboxDispatchResult.failed(
        ack.error?.message ?? 'Rejet de validation',
      );
    } on DioException catch (e) {
      // Réseau / timeout / 5xx : transitoire → retry (idempotent).
      return OutboxDispatchResult.retry(e.message ?? e.toString());
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
