import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';

/// Garde-fou FIFO : vrai si l'inscription locale de l'élève est SYNCED (ou s'il
/// n'y a pas d'inscription locale = élève préexistant). Câblé sur le DAO
/// Inscription en DI, stubbable en test.
typedef EnrollmentSyncGate = Future<bool> Function(String studentId);

/// Handler d'outbox de l'agrégat PAYMENT (FF-Lot 4).
///
/// **Garde FIFO** : si le paiement référence un élève dont l'inscription locale
/// n'est pas encore SYNCED, on renvoie `blocked` — attente PROPRE, pas un `retry`
/// (l'agrégat ENROLLMENT doit partir avant — l'uuid honoré garantit alors
/// `payment.student_id` = id serveur). Sinon `POST /api/v1/sync/payments` →
/// ACK : remap des allocations + créances provisoires, UPSERT des créances
/// autoritaires, scellement du reçu → `acked`. Idempotent sur `payment.id`.
class PaymentOutboxHandler implements OutboxSyncHandler {
  final FinanceSyncApi _api;
  final FinanceLocalDao _dao;
  final EnrollmentSyncGate _isStudentEnrollmentSynced;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const PaymentOutboxHandler({
    required FinanceSyncApi api,
    required FinanceLocalDao dao,
    required EnrollmentSyncGate isStudentEnrollmentSynced,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _isStudentEnrollmentSynced = isStudentEnrollmentSynced,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => 'PAYMENT';

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final PaymentAggregateRequest request;
    try {
      final map = jsonDecode(entry.payload) as Map<String, dynamic>;
      request = PaymentAggregateRequest.fromJson(map);
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }

    // Garde FIFO : le paiement ATTEND l'ACK de l'inscription de l'élève. C'est
    // une attente PROPRE (`blocked`) — ni attempts++, ni backoff, ni faux
    // SYNC_ERROR : l'argent reçu ne doit jamais être surfacé comme un conflit de
    // synchro (FRONT §6.3). Le lien se lève automatiquement à l'ACK.
    final ready = await _isStudentEnrollmentSynced(request.payment.studentId);
    if (!ready) {
      return const OutboxDispatchResult.blocked(
        'Inscription de l\'élève non synchronisée (dépendance)',
      );
    }

    try {
      final ack = await _api.commitPayment(_extras, request);
      // `charges` est `required` au contrat : un ACK sans créance autoritaire
      // est une panne SERVEUR, pas un encaissement acquitté. On ne l'applique
      // pas — sans miroir à intégrer, acquitter le paiement le sortirait du
      // `paid_pending` et rendrait la créance « impayée » → réencaissement.
      // `retry` : le POST est idempotent, le rejeu renverra un 200 canonique
      // dès que le serveur va bien, et l'outbox rend la panne visible.
      if (ack.charges.isEmpty) {
        return const OutboxDispatchResult.retry(
          'ACK sans créance autoritaire (contrat : `charges` requis)',
        );
      }
      await _dao.applyPaymentAck(ack, nowMs: _now());
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      // Un paiement n'est jamais rejeté métier (back FB-2) : tout est transitoire.
      return OutboxDispatchResult.retry(e.message ?? e.toString());
    } catch (e) {
      return OutboxDispatchResult.retry(e.toString());
    }
  }
}
