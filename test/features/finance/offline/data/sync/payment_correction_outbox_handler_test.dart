import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_ack_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_correction_sync_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_correction_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_composer.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/payment_correction_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_correction_outbox_handler.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_correction_request.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_correction_response.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../../offline_full_db.dart';

class _MockApi extends Mock implements FinanceSyncApi {}

class _MockSyncEngine extends Mock implements SyncEngine {}

StudentChargeDto _charge(int paid) => StudentChargeDto(
  id: 'c-1',
  studentId: 's-1',
  academicYearId: 'ay-1',
  feeCode: 'MINERVAL',
  label: 'Minerval',
  expectedAmountInCents: 15000,
  amountPaidInCents: paid,
  currency: 'USD',
  status: paid == 0 ? 'DUE' : 'PARTIAL',
);

DioException _refusal(
  int status, {
  String? detailCode,
  Map<String, dynamic>? details,
}) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: {'detailCode': ?detailCode, 'details': ?details},
  ),
);

/// Le handler de la correction (lot T3), sur une vraie base : l'attente de
/// l'origine, l'ACK, les refus, et les sorties de l'attente.
void main() {
  late Database db;
  late _MockApi api;
  late FinanceLocalDao ledger;
  late FinanceOfflineRepositoryImpl cashier;
  late PaymentCorrectionRepositoryImpl corrections;
  var enrollment = OutboxDependencyState.ready;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(
      const PaymentCorrectionRequest(
        id: 'x',
        paymentId: 'x',
        reasonCode: 'OTHER',
        clientCancelledAt: '',
      ),
    );
  });

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    enrollment = OutboxDependencyState.ready;
    final sync = _MockSyncEngine();
    when(() => sync.flush()).thenAnswer((_) async => const SyncFlushReport());
    const ids = IdGenerator(Uuid());
    final user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    ledger = FinanceLocalDao(db, ids);
    cashier = FinanceOfflineRepositoryImpl(
      dao: ledger,
      idGenerator: ids,
      syncEngine: sync,
      currentUser: user,
      now: () => 1000,
    );
    corrections = PaymentCorrectionRepositoryImpl(
      dao: PaymentCorrectionWriteDao(db, FinancePaymentWriteDao(db)),
      composer: PaymentComposer(idGenerator: ids, currentUser: user),
      idGenerator: ids,
      syncEngine: sync,
      currentUser: user,
      now: () => 2000,
    );
    await db.insert('student_charges', {
      'id': 'c-1',
      'student_id': 's-1',
      'academic_year_id': 'ay-1',
      'fee_code': 'MINERVAL',
      'label': 'Minerval',
      'expected_amount_in_cents': 15000,
      'currency': 'USD',
    });
  });

  tearDown(() async => db.close());

  PaymentCorrectionOutboxHandler handler() => PaymentCorrectionOutboxHandler(
    api: api,
    dao: PaymentCorrectionSyncDao(db, FinancePaymentAckDao(db)),
    dependency: (_, _) async => enrollment,
    idGenerator: const IdGenerator(Uuid()),
    extras: const {},
    now: () => 5000,
  );

  RecordPaymentDraft draftOf(int cents) => RecordPaymentDraft(
    studentId: 's-1',
    academicYearId: 'ay-1',
    paidAt: '2026-09-25T13:11:41Z',
    payerFirstName: 'Marie',
    payerLastName: 'Tshiala',
    allocations: [
      AllocationDraft(
        studentChargeId: 'c-1',
        feeCode: 'MINERVAL',
        studentChargeLabel: 'Minerval',
        amountInCents: cents,
        currency: 'USD',
      ),
    ],
  );

  /// Un versement de 150 $ encaissé puis acquitté par le serveur.
  Future<String> syncedOrigin() async {
    final id = (await cashier.recordPayment(
      draftOf(15000),
    )).getOrElse(() => throw StateError('refusé'));
    await db.update('payments', {'sync_status': 'SYNCED'});
    await db.update('student_charges', {'amount_paid_in_cents': 15000});
    await db.delete('outbox');
    return id;
  }

  Future<PaymentCorrectionOutcome> correct(String origin, {int? to}) async =>
      (await corrections.correctPayment(
        PaymentCorrectionDraft(
          paymentId: origin,
          reason: to == null
              ? PaymentCorrectionReason.duplicate
              : PaymentCorrectionReason.wrongAmount,
          replacement: to == null ? null : draftOf(to),
        ),
      )).getOrElse(() => throw StateError('refusé'));

  Future<OutboxEntry> correctionEntry() async => OutboxEntry.fromMap(
    (await db.query(
      'outbox',
      where: 'aggregate_type = ?',
      whereArgs: [kPaymentCorrectionAggregate],
    )).single,
  );

  Future<String?> statusOf(String correctionId) async =>
      (await db.query(
            'payment_corrections',
            where: 'id = ?',
            whereArgs: [correctionId],
          )).single['status']
          as String?;

  Future<int> remaining() async {
    final charge = (await ledger.getChargesByStudent('s-1')).single;
    return charge.expectedAmountInCents - charge.optimisticPaidInCents;
  }

  group('attente de l origine', () {
    test('un versement pas encore remonté fait attendre', () async {
      final origin = (await cashier.recordPayment(
        draftOf(15000),
      )).getOrElse(() => throw StateError('refusé'));
      await correct(origin);

      final result = await handler().dispatch(await correctionEntry());

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.correctPayment(any(), any()));
    });

    // R2 : sans cette sortie, `blocked` attendrait pour toujours.
    test('une origine refusée rend la correction locale', () async {
      final origin = (await cashier.recordPayment(
        draftOf(15000),
      )).getOrElse(() => throw StateError('refusé'));
      final outcome = await correct(origin, to: 5000);
      await db.update(
        'outbox',
        {'status': 'SYNC_ERROR'},
        where: 'aggregate_type = ? AND aggregate_id = ?',
        whereArgs: ['PAYMENT', origin],
      );

      final result = await handler().dispatch(await correctionEntry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await statusOf(outcome.correctionId), 'LOCAL_ONLY');
      final payments = await db.query(
        'outbox',
        where: 'aggregate_type = ?',
        whereArgs: ['PAYMENT'],
      );
      expect(payments.single['aggregate_id'], outcome.replacementPaymentId);
      expect(await remaining(), 10000);
    });

    test('l élève du remplaçant doit être connu du serveur', () async {
      final origin = await syncedOrigin();
      await correct(origin, to: 5000);
      enrollment = OutboxDependencyState.waiting;

      final result = await handler().dispatch(await correctionEntry());

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });
  });

  group('accusé', () {
    test('annulation seule : l origine est annulée par le serveur', () async {
      final origin = await syncedOrigin();
      final outcome = await correct(origin);
      when(() => api.correctPayment(any(), any())).thenAnswer(
        (_) async => PaymentCorrectionResponse(
          id: outcome.correctionId,
          paymentId: origin,
          cancelledAt: '2026-09-26T09:14:00Z',
          charges: [_charge(0)],
        ),
      );

      final result = await handler().dispatch(await correctionEntry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await statusOf(outcome.correctionId), 'APPLIED');
      final row = (await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: [origin],
      )).single;
      expect(row['cancelled_at'], isNotNull);
      // Créances du serveur, retranchement éteint : ni trou ni double compte.
      expect(await remaining(), 15000);
    });

    test(
      'correction : le remplaçant est acquitté comme un encaissement',
      () async {
        final origin = await syncedOrigin();
        final outcome = await correct(origin, to: 5000);
        final replacementId = outcome.replacementPaymentId!;
        when(() => api.correctPayment(any(), any())).thenAnswer(
          (_) async => PaymentCorrectionResponse(
            id: outcome.correctionId,
            paymentId: origin,
            cancelledAt: '2026-09-26T09:14:00Z',
            replacement: PaymentAggregateResponse(
              payment: AckPaymentRef(id: replacementId, receiptId: 'doc-2'),
              charges: [_charge(5000)],
              documents: const [
                GeneratedDocumentDto(
                  type: 'RC',
                  documentNumber: 'CF-RC-2627-000300',
                  status: 'DEFINITIVE',
                ),
              ],
            ),
            charges: [_charge(5000)],
          ),
        );

        await handler().dispatch(await correctionEntry());

        final replacement = (await db.query(
          'payments',
          where: 'id = ?',
          whereArgs: [replacementId],
        )).single;
        expect(replacement['sync_status'], 'SYNCED');
        expect(replacement['receipt_id'], 'doc-2');
        expect(await remaining(), 10000);
      },
    );

    test('un accusé sans créance est une panne : on réessaie', () async {
      final origin = await syncedOrigin();
      final outcome = await correct(origin);
      when(() => api.correctPayment(any(), any())).thenAnswer(
        (_) async => PaymentCorrectionResponse(
          id: outcome.correctionId,
          paymentId: origin,
          cancelledAt: '2026-09-26T09:14:00Z',
        ),
      );

      final result = await handler().dispatch(await correctionEntry());

      expect(result.outcome, OutboxDispatchOutcome.retry);
      expect(await statusOf(outcome.correctionId), 'PENDING');
    });
  });

  group('refus', () {
    // D4 : une autre tablette a gagné. Le serveur dit quand.
    test('PAYMENT_ALREADY_CORRECTED retire le remplaçant local', () async {
      final origin = await syncedOrigin();
      final outcome = await correct(origin, to: 5000);
      when(() => api.correctPayment(any(), any())).thenThrow(
        _refusal(
          422,
          detailCode: 'PAYMENT_ALREADY_CORRECTED',
          details: {
            'cancelledAt': '2026-09-26T08:00:00Z',
            'cancelledByName': 'Moke Junior',
          },
        ),
      );

      final result = await handler().dispatch(await correctionEntry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await statusOf(outcome.correctionId), 'REJECTED');
      expect(
        await db.query(
          'payments',
          where: 'id = ?',
          whereArgs: [outcome.replacementPaymentId],
        ),
        isEmpty,
      );
      final correction = (await db.query('payment_corrections')).single;
      expect(correction['sync_error_code'], 'PAYMENT_ALREADY_CORRECTED');
      expect(correction['server_detail'] as String, contains('Moke Junior'));
      final row = (await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: [origin],
      )).single;
      expect(row['cancelled_at'], isNotNull);
    });

    test('un 403 rétablit l origine', () async {
      final origin = await syncedOrigin();
      final outcome = await correct(origin);
      expect(await remaining(), 15000);
      when(() => api.correctPayment(any(), any())).thenThrow(_refusal(403));

      final result = await handler().dispatch(await correctionEntry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await statusOf(outcome.correctionId), 'REJECTED');
      expect(await remaining(), 0);
    });

    test('TARGET_NOT_ENROLLED est terminal', () async {
      final origin = await syncedOrigin();
      final outcome = await correct(origin, to: 5000);
      when(
        () => api.correctPayment(any(), any()),
      ).thenThrow(_refusal(422, detailCode: 'TARGET_NOT_ENROLLED'));

      await handler().dispatch(await correctionEntry());

      expect(await statusOf(outcome.correctionId), 'REJECTED');
    });

    for (final (label, error) in [
      (
        'PAYMENT_NOT_YET_SYNCED',
        _refusal(422, detailCode: 'PAYMENT_NOT_YET_SYNCED'),
      ),
      ('UNKNOWN_FEE_CODE', _refusal(422, detailCode: 'UNKNOWN_FEE_CODE')),
      ('un 503', _refusal(503)),
    ]) {
      test('$label se rejoue', () async {
        final origin = await syncedOrigin();
        final outcome = await correct(origin);
        when(() => api.correctPayment(any(), any())).thenThrow(error);

        final result = await handler().dispatch(await correctionEntry());

        expect(result.outcome, OutboxDispatchOutcome.retry);
        expect(await statusOf(outcome.correctionId), 'PENDING');
      });
    }
  });

  group('chaîne de corrections', () {
    Future<OutboxEntry> entryFor(String correctionId) async =>
        OutboxEntry.fromMap(
          (await db.query(
            'outbox',
            where: 'aggregate_id = ?',
            whereArgs: [correctionId],
          )).single,
        );

    test('corriger un remplaçant attend la correction qui le porte', () async {
      final origin = await syncedOrigin();
      final first = await correct(origin, to: 5000);
      final second = await correct(first.replacementPaymentId!, to: 4000);

      final result = await handler().dispatch(
        await entryFor(second.correctionId),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test('si elle est refusée, la suite est condamnée', () async {
      final origin = await syncedOrigin();
      final first = await correct(origin, to: 5000);
      final second = await correct(first.replacementPaymentId!, to: 4000);
      when(() => api.correctPayment(any(), any())).thenThrow(_refusal(403));
      await handler().dispatch(await entryFor(first.correctionId));

      final result = await handler().dispatch(
        await entryFor(second.correctionId),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await statusOf(second.correctionId), 'REJECTED');
      // L'origine reprend cours, seule.
      expect(await remaining(), 0);
    });
  });
}
