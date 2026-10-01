import 'dart:convert';

import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_cancellation_store.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_cancellation_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_disbursement_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Les versements de salaire (`payroll_disbursements`) : des faits. Un
/// versement refusé n'est **jamais effacé** — l'argent est parti ; il reste
/// en erreur, listé à régulariser.
class PayrollDisbursementDao {
  final PayrollStore _store;
  final PayrollCancellationStore cancellations;

  PayrollDisbursementDao._(this._store)
    : cancellations = PayrollCancellationStore(
        _store,
        table,
        PayrollOutbox.disbursement,
      );

  factory PayrollDisbursementDao(DatabaseExecutor db) =>
      PayrollDisbursementDao._(PayrollStore(db));

  static const String table = 'payroll_disbursements';

  static String entryId(String id) =>
      PayrollOutbox.entryId(PayrollOutbox.disbursement, id);

  static String cancellationEntryId(String cancellationId) =>
      PayrollOutbox.entryId(
        PayrollOutbox.disbursementCancellation,
        cancellationId,
      );

  Future<void> add(
    PayrollDisbursementRequestDto request, {
    required String schoolId,
    required int nowMs,
    String? authorName,
  }) {
    final disbursement = request.disbursement;
    return _store.write(
      table,
      {'id': disbursement.id},
      {
        'school_id': schoolId,
        ..._content(disbursement),
        'author_name': authorName,
        'created_at': nowMs,
      },
      _queued(request),
      schoolId: schoolId,
      nowMs: nowMs,
    );
  }

  static PayrollQueued _queued(PayrollDisbursementRequestDto request) {
    final disbursement = request.disbursement;
    return PayrollQueued(
      entryId: entryId(disbursement.id),
      aggregateType: PayrollOutbox.disbursement,
      aggregateId: PayrollOutbox.lineKey(
        disbursement.month,
        disbursement.staffMemberId,
      ),
      payload: request.toJson(),
    );
  }

  /// Régularisation (N2) : le **même** versement, rattaché à la nouvelle
  /// validation, repart. Le serveur n'a rien gardé du refus : c'est une
  /// première écriture, pas un rejeu. Seulement s'il est **encore** refusé et
  /// sans annulation — une annulation posée entre-temps l'emporte. Rend
  /// `true` s'il est reparti.
  Future<bool> reattach(
    PayrollDisbursementRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) => _store.transaction((txn) async {
    final updated = await txn.update(
      table,
      {
        'validation_gesture_id': request.disbursement.validationGestureId,
        'sync_status': RecordSyncState.pending.dbValue,
        'sync_error': null,
        'sync_error_code': null,
      },
      where: 'id = ? AND sync_status = ? AND cancellation_id IS NULL',
      whereArgs: [request.disbursement.id, RecordSyncState.failed.dbValue],
    );
    if (updated != 1) return false;
    await PayrollStore.enqueue(
      txn,
      _queued(request),
      schoolId: schoolId,
      nowMs: nowMs,
    );
    return true;
  });

  /// Qui a versé : l'auteur figé dans l'entrée d'outbox du versement, jamais
  /// la session du moment — un versement régularisé reste signé par celui
  /// qui a remis l'argent.
  Future<String?> authorOf(String id) async {
    final rows = await _store.db.query(
      OutboxDao.table,
      columns: ['payload'],
      where: 'id = ?',
      whereArgs: [entryId(id)],
    );
    if (rows.isEmpty) return null;
    try {
      return PayrollDisbursementRequestDto.tryParse(
        jsonDecode(rows.single['payload']! as String),
      )?.authorId;
    } catch (_) {
      return null;
    }
  }

  Future<void> cancel(
    PayrollCancellationRequestDto request, {
    required String month,
    required String staffMemberId,
    required String schoolId,
    required int nowMs,
  }) => cancellations.request(
    request.targetId,
    cancellationId: request.cancellationId,
    reason: request.reason,
    queued: PayrollQueued(
      entryId: cancellationEntryId(request.cancellationId),
      aggregateType: PayrollOutbox.disbursementCancellation,
      aggregateId: PayrollOutbox.lineKey(month, staffMemberId),
      payload: request.toJson(),
    ),
    schoolId: schoolId,
    nowMs: nowMs,
  );

  /// Une page descendue : un versement que le serveur connaît est acquis.
  Future<int> applyPulled(
    List<PayrollDisbursementDto> items, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (items.isEmpty || schoolId.isEmpty) return 0;
    await _store.transaction((txn) async {
      for (final item in items) {
        await PayrollStore.upsert(
          txn,
          table,
          {'id': item.id},
          {
            'school_id': schoolId,
            ..._content(item),
            if (item.recordedBy != null) 'author_name': item.recordedBy,
            ...PayrollCancellationStore.serverColumns(
              cancelledAt: item.cancelledAt,
              reason: item.cancellationReason,
            ),
            'server_updated_at': item.serverUpdatedAt,
            'sync_status': RecordSyncState.synced.dbValue,
            'sync_error': null,
            'sync_error_code': null,
          },
        );
      }
    });
    return items.length;
  }

  Future<void> mark(
    String id,
    RecordSyncState state, {
    String? code,
    String? reason,
  }) => _store.mark(table, {'id': id}, state, code: code, reason: reason);

  /// Un versement vivant — ou en file — existe-t-il déjà pour ce salaire ?
  /// La garde d'unicité de la tablette : deux taps, ou un pull arrivé pendant
  /// la saisie, ne remettent jamais l'argent deux fois.
  Future<bool> hasLive(String month, String staffMemberId) async {
    final rows = await _store.db.rawQuery(
      'SELECT 1 FROM $table WHERE month = ? AND staff_member_id = ? '
      "AND sync_status != '${RecordSyncState.failed.dbValue}' "
      'AND (cancellation_id IS NULL '
      "OR cancellation_status = '${RecordSyncState.failed.dbValue}') "
      'AND cancelled_at IS NULL LIMIT 1',
      [month, staffMemberId],
    );
    return rows.isNotEmpty;
  }

  Future<RecordSyncState?> stateOf(String id) async {
    final rows = await _store.db.query(
      table,
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty
        ? null
        : RecordSyncState.fromDb(rows.single['sync_status'] as String?);
  }

  Future<List<PayrollDisbursement>> forSchool(String schoolId) async {
    final rows = await _store.db.rawQuery(
      'SELECT f.*, '
      '${PayrollStore.effectiveStatusColumns('f', PayrollOutbox.disbursement)} '
      'FROM $table f WHERE f.school_id = ? '
      'ORDER BY f.paid_at ASC, f.created_at ASC',
      [schoolId],
    );
    return [for (final row in rows) _toEntity(row)];
  }

  /// La forme du fil d'un versement relu (régularisation).
  static PayrollDisbursementDto toWire(PayrollDisbursement disbursement) =>
      PayrollDisbursementDto(
        id: disbursement.id,
        month: disbursement.month,
        staffMemberId: disbursement.staffMemberId,
        validationGestureId: disbursement.validationGestureId,
        amountInCents: disbursement.amount.amountInCents,
        currency: disbursement.amount.currency,
        mode: disbursement.mode.wire,
        paidAt: disbursement.paidAt,
        operator: disbursement.operator?.wire,
        payoutPhone: disbursement.payoutPhone,
        reference: disbursement.reference,
        bankName: disbursement.bankName,
        bankAccount: disbursement.bankAccount,
        signedRegister: disbursement.signedRegister,
      );

  static PayrollDisbursement _toEntity(Map<String, Object?> row) =>
      PayrollDisbursement(
        id: row['id']! as String,
        month: row['month']! as String,
        staffMemberId: row['staff_member_id']! as String,
        validationGestureId: row['validation_gesture_id']! as String,
        amount: Money.parse(
          row['amount_in_cents']! as int,
          row['currency']! as String,
        ),
        mode: PayoutMode.fromWire(row['mode'] as String?) ?? PayoutMode.cash,
        operator: MobileMoneyOperator.fromWire(row['operator'] as String?),
        payoutPhone: row['payout_phone'] as String?,
        reference: row['reference'] as String?,
        bankName: row['bank_name'] as String?,
        bankAccount: row['bank_account'] as String?,
        signedRegister: (row['signed_register'] as int? ?? 0) == 1,
        paidAt: row['paid_at']! as String,
        authorName: row['author_name'] as String?,
        cancellation: PayrollCancellationStore.fromRow(row),
        syncState: PayrollStore.effectiveState(row),
        syncError: PayrollStore.effectiveError(row),
        syncErrorCode: row['sync_error_code'] as String?,
      );

  static Map<String, Object?> _content(PayrollDisbursementDto item) => {
    'month': item.month,
    'staff_member_id': item.staffMemberId,
    'validation_gesture_id': item.validationGestureId,
    'amount_in_cents': item.amountInCents,
    'currency': item.currency,
    'mode': item.mode,
    'operator': item.operator,
    'payout_phone': item.payoutPhone,
    'reference': item.reference,
    'bank_name': item.bankName,
    'bank_account': item.bankAccount,
    'signed_register': item.signedRegister ? 1 : 0,
    'paid_at': item.paidAt,
  };
}
