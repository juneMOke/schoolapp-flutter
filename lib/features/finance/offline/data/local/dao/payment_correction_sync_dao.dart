import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_ack_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_correction_request.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_correction_response.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';

/// Où en est le versement visé par une correction, vu de l'outbox.
enum CorrectionOriginReadiness {
  /// Synchronisé : la correction peut partir.
  ready,

  /// Pas encore synchronisé, et rien ne dit qu'il ne le sera pas : attendre.
  waiting,

  /// Refusé pour de bon par le serveur : il ne sera jamais synchronisé (R2).
  refused,

  /// Disparu, ou porté par une correction refusée : la correction n'a plus
  /// d'objet.
  condemned,
}

/// Ce que l'outbox fait d'une correction de versement (lot T3).
class PaymentCorrectionSyncDao {
  final Database _db;
  final FinancePaymentAckDao _ack;

  const PaymentCorrectionSyncDao(this._db, this._ack);

  /// L'état de la correction, `null` si elle n'existe plus.
  Future<PaymentCorrectionStatus?> statusOf(String correctionId) async {
    final rows = await _db.query(
      'payment_corrections',
      columns: const ['status'],
      where: 'id = ?',
      whereArgs: [correctionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PaymentCorrectionStatus.fromDbValue(rows.first['status'] as String?);
  }

  /// L'ordre est garanti PAR VERSEMENT, pas pour toute la file : une
  /// correction n'attend que son origine, et un refus ne bloque personne.
  Future<CorrectionOriginReadiness> originReadiness(String paymentId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT p.sync_status,
             EXISTS (
               SELECT 1 FROM outbox o
               WHERE o.aggregate_type = 'PAYMENT' AND o.aggregate_id = p.id
                 AND o.status = ?
             ) AS refused,
             EXISTS (
               SELECT 1 FROM payment_corrections pc
               WHERE pc.replacement_payment_id = p.id AND pc.status = ?
             ) AS carrier_rejected
      FROM payments p
      WHERE p.id = ?
      ''',
      [
        OutboxStatus.syncError.dbValue,
        PaymentCorrectionStatus.rejected.dbValue,
        paymentId,
      ],
    );
    if (rows.isEmpty) return CorrectionOriginReadiness.condemned;
    final r = rows.first;
    if (r['sync_status'] == SyncState.synced.dbValue) {
      return CorrectionOriginReadiness.ready;
    }
    if (((r['carrier_rejected'] as int?) ?? 0) != 0) {
      return CorrectionOriginReadiness.condemned;
    }
    if (r['sync_status'] == SyncState.syncError.dbValue ||
        ((r['refused'] as int?) ?? 0) != 0) {
      return CorrectionOriginReadiness.refused;
    }
    return CorrectionOriginReadiness.waiting;
  }

  /// L'accusé, en UNE transaction : ACK du remplaçant (même code que celui
  /// d'un encaissement), créances recalculées, annulation SERVEUR de
  /// l'origine, correction appliquée.
  ///
  /// Poser `cancelled_at` ici est légitime : c'est l'heure que le serveur
  /// vient de rendre. C'est aussi ce qui éteint le terme de retranchement au
  /// moment exact où les créances recalculées le rendent inutile.
  Future<void> applyAck(
    PaymentCorrectionResponse ack, {
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      final replacement = ack.replacement;
      if (replacement != null) {
        await _ack.applyPaymentAckIn(txn, replacement, nowMs: nowMs);
      }
      await _ack.applyAuthoritativeChargesIn(txn, ack.charges, nowMs: nowMs);
      await txn.update(
        'payments',
        {'cancelled_at': EpochIsoHelper.tryToEpochMs(ack.cancelledAt) ?? nowMs},
        where: 'id = ?',
        whereArgs: [ack.paymentId],
      );
      await txn.update(
        'payment_corrections',
        {
          'status': PaymentCorrectionStatus.applied.dbValue,
          'sync_error': null,
          'sync_error_code': null,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [ack.id],
      );
    });
  }

  /// Refus définitif (R3) : rien n'a changé côté serveur. L'origine reprend
  /// cours, le remplaçant local disparaît, et la ligne garde le motif.
  ///
  /// [serverCancelledAt] : l'annulation qu'un AUTRE geste a posée
  /// (`PAYMENT_ALREADY_CORRECTED`) — elle vient du serveur, elle s'écrit.
  Future<void> reject(
    String correctionId, {
    required String? errorCode,
    required String error,
    Map<String, dynamic>? serverDetail,
    int? serverCancelledAt,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      final rows = await txn.query(
        'payment_corrections',
        columns: const ['payment_id', 'replacement_payment_id'],
        where: 'id = ?',
        whereArgs: [correctionId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final replacementId = rows.first['replacement_payment_id'] as String?;
      if (replacementId != null) {
        await _deletePaymentRows(txn, replacementId);
      }
      if (serverCancelledAt != null) {
        await txn.update(
          'payments',
          {'cancelled_at': serverCancelledAt},
          where: 'id = ? AND cancelled_at IS NULL',
          whereArgs: [rows.first['payment_id']],
        );
      }
      await txn.update(
        'payment_corrections',
        {
          'status': PaymentCorrectionStatus.rejected.dbValue,
          'sync_error': error,
          'sync_error_code': errorCode,
          'server_detail': serverDetail == null
              ? null
              : jsonEncode(serverDetail),
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [correctionId],
      );
    });
  }

  /// R2, découvert APRÈS la mise en file : l'origine a été refusée pour de
  /// bon. La correction devient locale, l'entrée d'outbox de l'origine sort
  /// dans la même transaction, et le remplaçant part comme un encaissement
  /// ordinaire — le serveur n'a jamais connu l'origine.
  Future<void> convertToLocal(
    PaymentCorrectionRequest request, {
    required String replacementEntryId,
    String? schoolId,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      await txn.update(
        'payment_corrections',
        {
          'status': PaymentCorrectionStatus.localOnly.dbValue,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [request.id],
      );
      await txn.delete(
        'outbox',
        where: 'aggregate_type = ? AND aggregate_id = ?',
        whereArgs: ['PAYMENT', request.paymentId],
      );
      final replacement = request.replacement;
      if (replacement == null) return;
      await OutboxDao(txn).enqueue(
        OutboxEntry(
          id: replacementEntryId,
          aggregateType: 'PAYMENT',
          aggregateId: replacement.payment.id,
          operation: OutboxOperation.create,
          payload: jsonEncode({
            if (request.authorId != null) 'authorId': request.authorId,
            'payment': replacement.payment.toJson(),
            'allocations': replacement.allocations
                .map((a) => a.toJson())
                .toList(),
          }),
          schoolId: schoolId,
          createdAt: nowMs,
        ),
      );
    });
  }

  static Future<void> _deletePaymentRows(
    DatabaseExecutor txn,
    String paymentId,
  ) async {
    for (final table in const [
      'payment_allocations',
      'payment_tenders',
      'generated_documents',
    ]) {
      await txn.delete(table, where: 'payment_id = ?', whereArgs: [paymentId]);
    }
    await txn.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
  }
}
