import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_correction_sync_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_correction_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_error_codes.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/receipt/cancelled_receipt_recorder.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_correction_request.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';

/// Handler d'outbox de l'agrégat `PAYMENT_CORRECTION` (lot T3).
///
/// ## L'ordre, par versement et seulement par versement
///
/// Un versement encaissé hors ligne part toujours avant sa correction : tant
/// que l'origine n'est pas synchronisée, l'entrée attend en `blocked` — ni
/// tentative consommée, ni poison. Le moteur ne garantit aucun ordre, et la
/// file n'est JAMAIS arrêtée : une correction refusée ne bloque aucun
/// encaissement.
///
/// ⚠️ **`blocked` ne s'épuise jamais** (le piège du circuit des dépenses).
/// D'où les sorties : une origine refusée pour de bon convertit la correction
/// en correction locale (R2) ; une origine disparue, ou portée par une
/// correction refusée, la condamne sur-le-champ.
///
/// ## Refus
///
/// `PAYMENT_ALREADY_CORRECTED`, `TARGET_NOT_ENROLLED`, les codes d'encaissement
/// définitifs et le 403 sont terminaux, et le serveur n'a rien changé :
/// l'origine reprend cours, le remplaçant local est retiré, la ligne garde le
/// motif. L'entrée est alors acquittée — la remettre en file depuis la feuille
/// des erreurs n'obtiendrait que le même refus.
class PaymentCorrectionOutboxHandler implements OutboxSyncHandler {
  final FinanceSyncApi _api;
  final PaymentCorrectionSyncDao _dao;
  final OutboxDependencyGate _dependency;
  final IdGenerator _idGenerator;
  final Map<String, dynamic> _extras;
  final Clock _now;

  /// Marque le reçu d'origine annulé dans le cache des pièces (R8). Optionnel :
  /// sans lui, le pull des pièces le fera.
  ///
  /// ⚠️ Une FABRIQUE, résolue au premier accusé et pas à l'enregistrement :
  /// le handler s'enregistre avant que le module Documents n'ait posé le cache
  /// des pièces dans la DI.
  final CancelledReceiptRecorder Function()? _receipts;

  PaymentCorrectionOutboxHandler({
    required FinanceSyncApi api,
    required PaymentCorrectionSyncDao dao,
    required OutboxDependencyGate dependency,
    required IdGenerator idGenerator,
    required Map<String, dynamic> extras,
    Clock now = systemClock,
    CancelledReceiptRecorder Function()? receipts,
  }) : _receipts = receipts,
       _api = api,
       _dao = dao,
       _dependency = dependency,
       _idGenerator = idGenerator,
       _extras = extras,
       _now = now;

  @override
  String get aggregateType => kPaymentCorrectionAggregate;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    final PaymentCorrectionRequest request;
    try {
      request = PaymentCorrectionRequest.fromJson(
        jsonDecode(entry.payload) as Map<String, dynamic>,
      );
    } catch (e) {
      return OutboxDispatchResult.failed('Payload illisible : $e');
    }

    // Déjà tranchée (rejeu d'une entrée acquittée, correction effacée) :
    // plus rien à pousser.
    final status = await _dao.statusOf(request.id);
    if (status != PaymentCorrectionStatus.pending) {
      return const OutboxDispatchResult.acked();
    }

    switch (await _dao.originReadiness(request.paymentId)) {
      case CorrectionOriginReadiness.ready:
        break;
      case CorrectionOriginReadiness.waiting:
        return const OutboxDispatchResult.blocked(
          'Attend le versement d\'origine',
        );
      case CorrectionOriginReadiness.refused:
        await _dao.convertToLocal(
          request,
          replacementEntryId: _idGenerator.newId(),
          schoolId: entry.schoolId,
          nowMs: _now(),
        );
        return const OutboxDispatchResult.acked();
      case CorrectionOriginReadiness.condemned:
        await _dao.reject(
          request.id,
          errorCode: null,
          error: 'Le versement d\'origine n\'existe plus.',
          nowMs: _now(),
        );
        return const OutboxDispatchResult.acked();
    }

    // L'élève du remplaçant (peut-être un autre élève, D1) doit être connu du
    // serveur, comme pour tout encaissement.
    final replacement = request.replacement;
    if (replacement != null) {
      final dependency = await _dependency(
        replacement.payment.studentId,
        replacement.payment.academicYearId,
      );
      if (dependency != OutboxDependencyState.ready) {
        return const OutboxDispatchResult.blocked(
          'Inscription de l\'élève du remplaçant non synchronisée',
        );
      }
    }

    try {
      final ack = await _api.correctPayment(_extras, request);
      // Même règle que l'encaissement : un ACK sans créance autoritaire est une
      // panne serveur. L'appliquer éteindrait le retranchement sans que rien
      // ne l'ait remplacé.
      if (ack.charges.isEmpty) {
        return const OutboxDispatchResult.retry(
          'ACK sans créance autoritaire (contrat : `charges` requis)',
        );
      }
      final nowMs = _now();
      final receiptId = await _dao.applyAck(ack, nowMs: nowMs);
      // Après la transaction, jamais dedans : une autre base, best-effort.
      try {
        await _receipts?.call().record(
          documentId: receiptId,
          documentNumber: ack.cancelledReceiptNumber,
          cancelledAt: EpochIsoHelper.tryToEpochMs(ack.cancelledAt) ?? nowMs,
          reason: request.reason,
        );
      } catch (_) {
        // Best-effort, comme l'enregistrement lui-même.
      }
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      return _onHttpError(request, e);
    } catch (e) {
      // Échec LOCAL après un POST possiblement appliqué : le rejeu rendra 200
      // et l'état canonique.
      return OutboxDispatchResult.retry(e.toString());
    }
  }

  /// Transitoires hormis les 5xx, comme pour l'encaissement.
  static const Set<int> _transientStatuses = {401, 408, 409, 429};

  Future<OutboxDispatchResult> _onHttpError(
    PaymentCorrectionRequest request,
    DioException e,
  ) async {
    final status = e.response?.statusCode;
    final detailCode = ApiErrorParser.detailCodeOf(e.response);
    final reason = _reasonOf(e, status, detailCode);

    if (status == null ||
        status >= 500 ||
        _transientStatuses.contains(status) ||
        detailCode == FinanceErrorCodes.paymentNotYetSynced ||
        FinanceErrorCodes.isTransient(detailCode)) {
      return OutboxDispatchResult.retry(reason);
    }

    final details = ApiErrorParser.detailsOf(e.response);
    await _dao.reject(
      request.id,
      errorCode: detailCode ?? 'HTTP_$status',
      error: reason,
      serverDetail: details,
      serverCancelledAt: detailCode == FinanceErrorCodes.paymentAlreadyCorrected
          ? EpochIsoHelper.tryToEpochMs(details?['cancelledAt'] as String?)
          : null,
      nowMs: _now(),
    );
    return const OutboxDispatchResult.acked();
  }

  static String _reasonOf(DioException e, int? status, String? detailCode) {
    final message = ApiErrorParser.serverMessageOf(e.response);
    final head = detailCode ?? (status != null ? 'HTTP $status' : 'réseau');
    return message == null || message.isEmpty ? head : '$head — $message';
  }
}
