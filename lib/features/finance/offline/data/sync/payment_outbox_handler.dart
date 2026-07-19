import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';

/// Handler d'outbox de l'agrégat PAYMENT (FF-Lot 4).
///
/// **Garde de dépendance ENROLLMENT→PAYMENT**, scopée à l'année du paiement (cf.
/// [OutboxDependencyState]) : selon l'état local de l'inscription de l'élève sur
/// cette année — `waiting` **et** `parentFailed` → `blocked` (attente PROPRE,
/// pas un `retry` : l'agrégat ENROLLMENT doit partir avant — l'uuid honoré
/// garantit alors `payment.student_id` = id serveur ; se lève dès que
/// l'inscription passe `SYNCED`, y compris après correction d'un `SYNC_ERROR`) ;
/// `ready` → `POST /api/v1/sync/payments` → ACK : remap des allocations +
/// créances provisoires, UPSERT des créances autoritaires, scellement du reçu →
/// `acked`. Idempotent sur `payment.id`.
///
/// **Classification des échecs HTTP** (cf. [_classifyDioError]) : transitoire
/// (`retry`, rejoué avec backoff) pour le transport, les 5xx et 401/408/409/429 ;
/// déterministe (`failed`, basculé SYNC_ERROR et surfacé au guichet) pour les
/// autres 4xx — le POST étant idempotent, un 4xx signifie que le serveur n'a
/// rien encaissé, donc rejouer jusqu'au poison ne ferait que retarder le même
/// SYNC_ERROR.
class PaymentOutboxHandler implements OutboxSyncHandler {
  final FinanceSyncApi _api;
  final FinanceLocalDao _dao;
  final OutboxDependencyGate _dependency;
  final Map<String, dynamic> _extras;
  final Clock _now;

  const PaymentOutboxHandler({
    required FinanceSyncApi api,
    required FinanceLocalDao dao,
    required OutboxDependencyGate dependency,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
  }) : _api = api,
       _dao = dao,
       _dependency = dependency,
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

    // Garde de dépendance ENROLLMENT→PAYMENT, scopée à l'année du paiement.
    // `waiting` ET `parentFailed` → `blocked` : attente PROPRE (ni attempts++,
    // ni backoff, ni faux SYNC_ERROR) — l'argent reçu ne doit jamais être
    // surfacé comme un conflit de synchro (FRONT §6.3). On NE bascule PAS un
    // paiement en SYNC_ERROR sur `parentFailed` : ce serait un cul-de-sac (aucun
    // chemin de re-push d'une entrée SYNC_ERROR), alors que `blocked` reste
    // AUTO-CICATRISANT — l'erreur d'inscription est déjà surfacée de son côté,
    // et dès qu'elle est corrigée → SYNCED, le paiement repart seul au flush
    // suivant. Le montant reste déduit en local (compose sur `sync_status <>
    // SYNCED`) entre-temps.
    switch (await _dependency(
      request.payment.studentId,
      request.payment.academicYearId,
    )) {
      case OutboxDependencyState.waiting:
        return const OutboxDispatchResult.blocked(
          'Inscription de l\'élève non synchronisée (dépendance)',
        );
      case OutboxDependencyState.parentFailed:
        return const OutboxDispatchResult.blocked(
          'Inscription de l\'élève en échec de synchro — corrigez '
          'l\'inscription, le paiement repartira ensuite',
        );
      case OutboxDependencyState.ready:
        break;
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
      return _classifyDioError(e);
    } catch (e) {
      // Échec LOCAL (ex. `applyPaymentAck`) après un POST possiblement acquitté :
      // impossible de distinguer un verrou SQLite transitoire d'un bug d'apply
      // déterministe. Retry-biaisé, sens de panne sûr pour l'argent — le POST
      // est idempotent (rejeu = 200 canonique) et, au pire, le poison finit par
      // surfacer un SYNC_ERROR. Le montant reste déduit en local entre-temps.
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  /// Statuts HTTP **transitoires** hormis les 5xx : jeton expiré (401,
  /// l'intercepteur ré-authentifie → le rejeu passe), timeout de requête (408),
  /// conflit à rejouer après refetch (409, cf. [OutboxDispatchOutcome.retry]),
  /// débordement de débit (429).
  static const Set<int> _transientStatuses = {401, 408, 409, 429};

  /// Classe un échec HTTP du POST paiement en **transitoire** (`retry`) ou
  /// **déterministe** (`failed`).
  ///
  /// Le POST est idempotent sur `payment.id` : un paiement réellement encaissé
  /// renverrait 200 au rejeu, jamais un 4xx — donc un 4xx client signifie que le
  /// serveur n'a RIEN encaissé. Le rejouer jusqu'au poison ne ferait que
  /// retarder le même SYNC_ERROR en gaspillant des tentatives ; on surface
  /// directement pour correction au guichet. Le montant reste déduit en local
  /// (`getChargesByStudent` compose sur `sync_status <> SYNCED`, SYNC_ERROR
  /// inclus) → le cash reçu n'est jamais « reperdu ».
  ///
  /// Restent transitoires : la couche transport (pas de réponse HTTP), tous les
  /// 5xx, et les [_transientStatuses].
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
