import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_composer.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_correction_request.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_origin.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';

/// Agrégat d'outbox d'une correction de versement.
const String kPaymentCorrectionAggregate = 'PAYMENT_CORRECTION';

/// L'état du versement visé, lu avant le geste.
class CorrectionOrigin {
  final String id;
  final String studentId;
  final String syncStatus;
  final bool serverCancelled;

  /// Une correction qui l'écarte déjà des soldes (en attente, appliquée ou
  /// locale) : aucun second geste n'est possible.
  final bool alreadyCorrected;

  /// Le serveur a refusé l'origine pour de bon : son entrée d'outbox est en
  /// `SYNC_ERROR`. ⚠️ Lu sur l'OUTBOX : le moteur n'écrit jamais l'échec dans
  /// `payments.sync_status`, qui reste `PENDING_SYNC`.
  final bool refusedByServer;

  const CorrectionOrigin({
    required this.id,
    required this.studentId,
    required this.syncStatus,
    required this.serverCancelled,
    required this.alreadyCorrected,
    this.refusedByServer = false,
  });
}

/// Ce que le geste écrit, en une transaction (lot T2).
class PaymentCorrectionWrite {
  final String correctionId;
  final CorrectionOrigin origin;
  final String reasonCode;
  final String? reason;
  final bool cashMoved;
  final String? authorId;
  final ComposedPayment? replacement;

  /// L'origine n'a jamais été acceptée par le serveur (R2) : rien ne part au
  /// nom de la correction, et l'entrée d'outbox de l'origine est retirée.
  final bool localOnly;

  const PaymentCorrectionWrite({
    required this.correctionId,
    required this.origin,
    required this.reasonCode,
    this.reason,
    this.cashMoved = false,
    this.authorId,
    this.replacement,
    this.localOnly = false,
  });
}

/// Écrit une correction de versement, sans jamais toucher
/// `payments.cancelled_at` : l'annulation locale vit dans
/// `payment_corrections`, et les lectures de solde la composent
/// (`PaymentInForceSql`).
class PaymentCorrectionWriteDao {
  final Database _db;
  final FinancePaymentWriteDao _payments;

  const PaymentCorrectionWriteDao(this._db, this._payments);

  /// L'origine telle que la tablette la connaît, `null` si elle est absente.
  Future<CorrectionOrigin?> findOrigin(String paymentId) =>
      _findOrigin(_db, paymentId);

  /// Le versement à corriger, avec ses imputations et la devise de son
  /// tiroir, `null` s'il est absent.
  Future<PaymentCorrectionOrigin?> loadOrigin(String paymentId) async {
    final payments = await _db.query(
      'payments',
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (payments.isEmpty) return null;
    final p = payments.first;
    final allocations = await _db.query(
      'payment_allocations',
      columns: const [
        'student_charge_id',
        'fee_code',
        'amount_in_cents',
        'currency',
      ],
      where: 'payment_id = ?',
      whereArgs: [paymentId],
      orderBy: 'id',
    );
    final tenders = await _db.query(
      'payment_tenders',
      columns: const ['currency', 'pivot_currency'],
      where: 'payment_id = ?',
      whereArgs: [paymentId],
    );
    return PaymentCorrectionOrigin(
      paymentId: paymentId,
      studentId: p['student_id'] as String,
      academicYearId: p['academic_year_id'] as String?,
      paidAt: p['paid_at'] as String,
      payerFirstName: p['payer_first_name'] as String?,
      payerLastName: p['payer_last_name'] as String?,
      payerMiddleName: p['payer_middle_name'] as String?,
      payerPhoneNumber: p['payer_phone_number'] as String?,
      allocations: [
        for (final a in allocations)
          PaymentCorrectionOriginAllocation(
            studentChargeId: a['student_charge_id'] as String?,
            feeCode: a['fee_code'] as String,
            amountInCents: a['amount_in_cents'] as int,
            currency: a['currency'] as String,
          ),
      ],
      tenderCurrencyByChargeCurrency: {
        for (final t in tenders)
          if (t['currency'] != t['pivot_currency'])
            t['pivot_currency'] as String: t['currency'] as String,
      },
    );
  }

  /// Le geste, en UNE transaction : correction inscrite, remplaçant écrit avec
  /// son reçu `PROV-…`, entrée d'outbox.
  ///
  /// L'origine est relue DANS la transaction : un pull ou un autre geste a pu
  /// l'annuler depuis que l'écran l'a montrée. Lève alors [StateError], et
  /// rien n'est écrit.
  Future<void> recordCorrection(
    PaymentCorrectionWrite write, {
    required String outboxEntryId,
    String? schoolId,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      final origin = await _findOrigin(txn, write.origin.id);
      if (origin == null || origin.serverCancelled || origin.alreadyCorrected) {
        throw StateError('Versement introuvable ou déjà annulé.');
      }

      final replacement = write.replacement;
      await txn.insert('payment_corrections', {
        'id': write.correctionId,
        'payment_id': origin.id,
        'student_id': origin.studentId,
        'replacement_payment_id': replacement?.payment.id,
        'reason_code': write.reasonCode,
        'reason': write.reason,
        'cash_moved': write.cashMoved ? 1 : 0,
        'client_cancelled_at': DateTime.fromMillisecondsSinceEpoch(
          nowMs,
          isUtc: true,
        ).toIso8601String(),
        'author_id': write.authorId,
        'status': write.localOnly
            ? PaymentCorrectionStatus.localOnly.dbValue
            : PaymentCorrectionStatus.pending.dbValue,
        'created_at': nowMs,
        'updated_at': nowMs,
      });

      final replacementRequest = replacement == null
          ? null
          : await _payments.writePaymentRows(
              txn,
              payment: replacement.payment,
              allocations: replacement.allocations,
              tenders: replacement.tenders,
              receipt: replacement.receipt,
              authorId: write.authorId,
            );

      if (write.localOnly) {
        // R2 : l'origine a été refusée pour de bon. Son entrée d'outbox sort
        // DANS la même transaction que la correction qui l'écarte des soldes :
        // c'est l'abandon sûr que le socle réserve aux modules. Sans ce
        // retrait, « Réessayer » la remettrait en file et l'origine
        // coexisterait avec son remplaçant côté serveur.
        await txn.delete(
          'outbox',
          where: 'aggregate_type = ? AND aggregate_id = ?',
          whereArgs: ['PAYMENT', origin.id],
        );
        if (replacementRequest != null) {
          // Le serveur n'a jamais connu l'origine : le remplaçant part comme
          // un encaissement ordinaire, sans référence à elle.
          await OutboxDao(txn).enqueue(
            OutboxEntry(
              id: outboxEntryId,
              aggregateType: 'PAYMENT',
              aggregateId: replacement!.payment.id,
              operation: OutboxOperation.create,
              payload: jsonEncode(replacementRequest.toJson()),
              schoolId: schoolId,
              createdAt: nowMs,
            ),
          );
        }
        return;
      }

      final request = PaymentCorrectionRequest(
        id: write.correctionId,
        paymentId: origin.id,
        reasonCode: write.reasonCode,
        reason: write.reason,
        cashMoved: write.cashMoved,
        clientCancelledAt: DateTime.fromMillisecondsSinceEpoch(
          nowMs,
          isUtc: true,
        ).toIso8601String(),
        authorId: write.authorId,
        replacement: replacementRequest,
      );
      await OutboxDao(txn).enqueue(
        OutboxEntry(
          id: outboxEntryId,
          aggregateType: kPaymentCorrectionAggregate,
          aggregateId: write.correctionId,
          operation: OutboxOperation.create,
          payload: jsonEncode(request.toJson()),
          schoolId: schoolId,
          createdAt: nowMs,
        ),
      );
    });
  }

  static Future<CorrectionOrigin?> _findOrigin(
    DatabaseExecutor db,
    String paymentId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT p.id, p.student_id, p.sync_status, p.cancelled_at,
             EXISTS (
               SELECT 1 FROM payment_corrections pc
               WHERE pc.payment_id = p.id AND pc.status IN (?, ?, ?)
             ) AS corrected,
             (p.sync_status = ? OR EXISTS (
               SELECT 1 FROM outbox o
               WHERE o.aggregate_type = 'PAYMENT' AND o.aggregate_id = p.id
                 AND o.status = ?
             )) AS refused
      FROM payments p
      WHERE p.id = ?
      ''',
      [
        PaymentCorrectionStatus.pending.dbValue,
        PaymentCorrectionStatus.applied.dbValue,
        PaymentCorrectionStatus.localOnly.dbValue,
        SyncState.syncError.dbValue,
        OutboxStatus.syncError.dbValue,
        paymentId,
      ],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return CorrectionOrigin(
      id: r['id'] as String,
      studentId: r['student_id'] as String,
      syncStatus: (r['sync_status'] as String?) ?? 'PENDING_SYNC',
      serverCancelled: r['cancelled_at'] != null,
      alreadyCorrected: ((r['corrected'] as int?) ?? 0) != 0,
      refusedByServer: ((r['refused'] as int?) ?? 0) != 0,
    );
  }
}
