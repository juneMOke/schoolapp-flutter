import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_cancellation_store.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_cancellation_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/salary_advance_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les avances sur salaire (`salary_advances`) : des faits, octroyés sur la
/// tablette et annulés par un geste, jamais effacés.
class SalaryAdvanceDao {
  final PayrollStore _store;
  final PayrollCancellationStore cancellations;

  SalaryAdvanceDao._(this._store)
    : cancellations = PayrollCancellationStore(_store, table);

  factory SalaryAdvanceDao(DatabaseExecutor db) =>
      SalaryAdvanceDao._(PayrollStore(db));

  static const String table = 'salary_advances';

  static String entryId(String id) =>
      PayrollOutbox.entryId(PayrollOutbox.advance, id);

  static String cancellationEntryId(String cancellationId) =>
      PayrollOutbox.entryId(PayrollOutbox.advanceCancellation, cancellationId);

  /// Octroie l'avance et la met en file. Elle attend, derrière les gestes du
  /// mois où elle commence, ce qui a été posé avant elle.
  Future<void> add(
    SalaryAdvanceRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) {
    final advance = request.advance;
    return _store.write(
      table,
      {'id': advance.id},
      {'school_id': schoolId, ..._content(advance), 'created_at': nowMs},
      PayrollQueued(
        entryId: entryId(advance.id),
        aggregateType: PayrollOutbox.advance,
        aggregateId: PayrollOutbox.monthKey(advance.firstMonth),
        payload: request.toJson(),
      ),
      schoolId: schoolId,
      nowMs: nowMs,
    );
  }

  Future<void> cancel(
    PayrollCancellationRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) => cancellations.request(
    request.targetId,
    cancellationId: request.cancellationId,
    reason: request.reason,
    queued: PayrollQueued(
      entryId: cancellationEntryId(request.cancellationId),
      aggregateType: PayrollOutbox.advanceCancellation,
      aggregateId: PayrollOutbox.advanceKey(request.targetId),
      payload: request.toJson(),
    ),
    schoolId: schoolId,
    nowMs: nowMs,
  );

  /// Une page descendue : une avance que le serveur connaît est acquise, même
  /// si l'accusé de son envoi s'est perdu. Son annulation locale en attente
  /// n'est pas effacée tant que le serveur n'en dit rien.
  Future<int> applyPulled(
    List<SalaryAdvanceDto> items, {
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
            'deducted_in_cents': item.deductedInCents ?? 0,
            'balance_in_cents': item.balanceInCents,
            ...PayrollCancellationStore.serverColumns(
              cancelledAt: item.cancelledAt,
              reason: item.cancellationReason,
            ),
            'server_updated_at': item.serverUpdatedAt,
            'sync_status': StaffSyncState.synced.dbValue,
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
    StaffSyncState state, {
    String? code,
    String? reason,
  }) => _store.mark(table, {'id': id}, state, code: code, reason: reason);

  Future<StaffSyncState?> stateOf(String id) async {
    final rows = await _store.db.query(
      table,
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty
        ? null
        : StaffSyncState.fromDb(rows.single['sync_status'] as String?);
  }

  Future<List<SalaryAdvance>> forSchool(String schoolId) async {
    final rows = await _store.db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'granted_on DESC, created_at DESC',
    );
    return [
      for (final row in rows)
        SalaryAdvance(
          id: row['id']! as String,
          staffMemberId: row['staff_member_id']! as String,
          amount: Money.parse(
            row['amount_in_cents']! as int,
            row['currency']! as String,
          ),
          installments: row['installments']! as int,
          firstMonth: row['first_month']! as String,
          reason:
              SalaryAdvanceReason.fromWire(row['reason'] as String?) ??
              SalaryAdvanceReason.other,
          reasonDetail: row['reason_detail'] as String?,
          mode: PayoutMode.fromWire(row['mode'] as String?) ?? PayoutMode.cash,
          grantedOn: row['granted_on']! as String,
          deductedInCents: row['deducted_in_cents'] as int? ?? 0,
          balanceInCents: row['balance_in_cents'] as int?,
          cancellation: PayrollCancellationStore.fromRow(row),
          syncState: StaffSyncState.fromDb(row['sync_status'] as String?),
          syncError: row['sync_error'] as String?,
          syncErrorCode: row['sync_error_code'] as String?,
        ),
    ];
  }

  static Map<String, Object?> _content(SalaryAdvanceDto advance) => {
    'staff_member_id': advance.staffMemberId,
    'amount_in_cents': advance.amountInCents,
    'currency': advance.currency,
    'installments': advance.installments,
    'first_month': advance.firstMonth,
    'reason': advance.reason,
    'reason_detail': advance.reasonDetail,
    'mode': advance.mode,
    'granted_on': advance.grantedOn,
    'client_recorded_at': advance.clientRecordedAt,
  };
}
