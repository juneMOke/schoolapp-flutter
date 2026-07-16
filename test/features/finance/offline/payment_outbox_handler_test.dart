import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_outbox_handler.dart';

import '../../offline_full_db.dart';

class MockFinanceSyncApi extends Mock implements FinanceSyncApi {}

class SeqIdGenerator extends IdGenerator {
  SeqIdGenerator() : super(const Uuid());
  int _i = 0;
  @override
  String newId() => 'id-${_i++}';
}

void main() {
  late Database db;
  late FinanceLocalDao dao;
  late MockFinanceSyncApi api;

  setUpAll(() {
    registerFallbackValue(
      const CreatePaymentRequest(
        id: 'x',
        studentId: 'x',
        academicYearId: 'x',
        amountInCents: 0,
        currency: 'USD',
        paidAt: 'x',
        payerFirstName: 'x',
        payerLastName: 'x',
        allocations: [],
      ),
    );
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FinanceLocalDao(db, SeqIdGenerator());
    api = MockFinanceSyncApi();

    await db.insert('student_charges', {
      'id': 'c1',
      'student_id': 's1',
      'fee_code': 'TUITION',
      'label': 'Scolarité',
      'expected_amount_in_cents': 100000,
      'amount_paid_in_cents': 0,
      'optimistic_paid_in_cents': 0,
      'currency': 'USD',
      'status': 'DUE',
      'sync_status': 'SYNCED',
    });
    await dao.recordPayment(
      payment: const PaymentLocalModel(
        id: 'pay1',
        clientUuid: 'pay1',
        studentId: 's1',
        academicYearId: 'ay-1',
        amountInCents: 30000,
        currency: 'USD',
        paidAt: '2026-07-06T10:00:00Z',
        payerFirstName: 'S',
        payerLastName: 'M',
      ),
      allocations: const [
        PaymentAllocationLocalModel(
          id: 'a1',
          clientUuid: 'a1',
          paymentId: 'pay1',
          studentChargeId: 'c1',
          feeCode: 'TUITION',
          studentChargeLabel: 'Scolarité',
          amountInCents: 30000,
          currency: 'USD',
        ),
      ],
      outboxEntryId: 'ob-pay',
      nowMs: 1000,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<OutboxEntry> pendingEntry() async =>
      (await OutboxDao(db).pendingReady(9999)).single;

  PaymentOutboxHandler handlerWithGate(bool ready) => PaymentOutboxHandler(
    api: api,
    dao: dao,
    isStudentEnrollmentSynced: (_) async => ready,
    extras: const {},
    now: () => 9000,
  );

  test('garde FIFO : inscription non synchronisée → blocked (attente propre, '
      'jamais retry/SYNC_ERROR), aucun POST', () async {
    final handler = handlerWithGate(false);
    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.commitPayment(any(), any()));
    expect(
      (await db.query('payments')).first['sync_status'],
      SyncState.pendingSync.dbValue,
    );
  });

  test(
    'inscription SYNCED → POST → acked + soldes autoritaires écrasés',
    () async {
      when(() => api.commitPayment(any(), any())).thenAnswer(
        (_) async => const PaymentCommitAck(
          paymentId: 'pay1',
          payment: AckPayment(id: 'pay1', status: 'CONFIRMED'),
          allocations: [AckAllocation(id: 'a1', studentChargeId: 'c1')],
          updatedCharges: [
            AckCharge(id: 'c1', amountPaidInCents: 30000, status: 'PARTIAL'),
          ],
        ),
      );

      final handler = handlerWithGate(true);
      final result = await handler.dispatch(await pendingEntry());
      expect(result.outcome, OutboxDispatchOutcome.acked);

      final charge = (await db.query('student_charges')).first;
      expect(charge['amount_paid_in_cents'], 30000);
      expect(charge['status'], 'PARTIAL');
      expect(
        (await db.query('payments')).first['sync_status'],
        SyncState.synced.dbValue,
      );
    },
  );

  test('erreur réseau → retry (jamais rejeté métier)', () async {
    when(() => api.commitPayment(any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: 'net',
      ),
    );
    final handler = handlerWithGate(true);
    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });
}
