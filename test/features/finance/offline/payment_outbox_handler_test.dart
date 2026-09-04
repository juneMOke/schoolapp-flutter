import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart'
    show StudentChargeDto;
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_outbox_handler.dart';

import '../../offline_full_db.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

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
      const PaymentAggregateRequest(
        payment: PaymentInput(
          id: 'x',
          studentId: 'x',
          amounts: MoneyBag.empty,
          paidAt: 'x',
        ),
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

  PaymentOutboxHandler handlerWithGate(OutboxDependencyState dep) =>
      PaymentOutboxHandler(
        api: api,
        dao: dao,
        dependency: (_, _) async => dep,
        extras: const {},
        now: () => 9000,
      );

  test('gate waiting : inscription en vol → blocked (attente propre, '
      'jamais retry/SYNC_ERROR), aucun POST', () async {
    final handler = handlerWithGate(OutboxDependencyState.waiting);
    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.commitPayment(any(), any()));
    expect(
      (await db.query('payments')).first['sync_status'],
      SyncState.pendingSync.dbValue,
    );
  });

  test('gate parentFailed : inscription en échec → blocked (AUTO-CICATRISANT, '
      'pas de SYNC_ERROR terminal irrécupérable), aucun POST', () async {
    final handler = handlerWithGate(OutboxDependencyState.parentFailed);
    final result = await handler.dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.blocked);
    // Message distinct du `waiting` (discrimine sur « corrigez »).
    expect(result.error, contains('corrigez'));
    verifyNever(() => api.commitPayment(any(), any()));
    // Le paiement reste PENDING_SYNC (montant déduit en local), repartira dès
    // l'inscription corrigée.
    expect(
      (await db.query('payments')).first['sync_status'],
      SyncState.pendingSync.dbValue,
    );
  });

  test('la sonde est interrogée avec le studentId ET l\'année du paiement '
      '(le bon champ est passé, pas payerId/paymentId)', () async {
    String? seenStudent;
    String? seenYear;
    final handler = PaymentOutboxHandler(
      api: api,
      dao: dao,
      dependency: (studentId, academicYearId) async {
        seenStudent = studentId;
        seenYear = academicYearId;
        return OutboxDependencyState.waiting; // court-circuite le POST
      },
      extras: const {},
      now: () => 9000,
    );
    await handler.dispatch(await pendingEntry());
    expect(seenStudent, 's1');
    expect(seenYear, 'ay-1');
  });

  test(
    'inscription SYNCED → POST → acked + soldes autoritaires écrasés',
    () async {
      when(() => api.commitPayment(any(), any())).thenAnswer(
        (_) async => const PaymentAggregateResponse(
          payment: AckPaymentRef(id: 'pay1'),
          allocations: [
            AllocationRemap(
              providedId: 'a1',
              canonicalId: 'a1',
              canonicalStudentChargeId: 'c1',
              feeCode: 'TUITION',
            ),
          ],
          charges: [
            StudentChargeDto(
              id: 'c1',
              studentId: 's1',
              feeCode: 'TUITION',
              label: 'Scolarité',
              expectedAmountInCents: 100000,
              amountPaidInCents: 30000,
              currency: 'USD',
              status: 'PARTIAL',
            ),
          ],
        ),
      );

      final handler = handlerWithGate(OutboxDependencyState.ready);
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

  test(
    'l\'agrégat POSTé est bien la forme imbriquée du contrat, relue depuis le '
    'payload outbox (uuid client honoré = clé d\'idempotence)',
    () async {
      when(() => api.commitPayment(any(), any())).thenAnswer(
        (_) async =>
            const PaymentAggregateResponse(payment: AckPaymentRef(id: 'pay1')),
      );

      await handlerWithGate(
        OutboxDependencyState.ready,
      ).dispatch(await pendingEntry());

      final sent =
          verify(() => api.commitPayment(any(), captureAny())).captured.single
              as PaymentAggregateRequest;
      expect(sent.payment.id, 'pay1');
      expect(sent.payment.studentId, 's1');
      // Dérivés des imputations, comme côté serveur : le versement n'a plus de
      // montant à lui.
      expect(sent.payment.amounts, MoneyBag.of(const [Money(30000, 'USD')]));
      expect(sent.allocations.single.feeCode, 'TUITION');
    },
  );

  DioException dioWithStatus(int status) => DioException(
    requestOptions: RequestOptions(path: '/x'),
    response: Response(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: status,
    ),
  );

  test(
    'erreur réseau (pas de réponse HTTP) → retry (transport transitoire)',
    () async {
      when(() => api.commitPayment(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: 'net',
        ),
      );
      final result = await handlerWithGate(
        OutboxDependencyState.ready,
      ).dispatch(await pendingEntry());
      expect(result.outcome, OutboxDispatchOutcome.retry);
    },
  );

  test('5xx → retry (panne serveur temporaire)', () async {
    when(() => api.commitPayment(any(), any())).thenThrow(dioWithStatus(503));
    final result = await handlerWithGate(
      OutboxDependencyState.ready,
    ).dispatch(await pendingEntry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  for (final status in [401, 408, 409, 429]) {
    test(
      '$status → retry (transitoire : jeton/timeout/conflit/débit)',
      () async {
        when(
          () => api.commitPayment(any(), any()),
        ).thenThrow(dioWithStatus(status));
        final result = await handlerWithGate(
          OutboxDependencyState.ready,
        ).dispatch(await pendingEntry());
        expect(result.outcome, OutboxDispatchOutcome.retry);
      },
    );
  }

  for (final status in [400, 403, 413, 415, 422]) {
    test(
      '$status → failed (4xx déterministe surfacé, pas de retry-jusqu\'au-poison)',
      () async {
        when(
          () => api.commitPayment(any(), any()),
        ).thenThrow(dioWithStatus(status));
        final result = await handlerWithGate(
          OutboxDependencyState.ready,
        ).dispatch(await pendingEntry());
        expect(result.outcome, OutboxDispatchOutcome.failed);
      },
    );
  }

  // ── Le serveur NOMME la cause d'un 422 ──────────────────────────────────────
  //
  // Le statut seul ne suffit plus : toutes les causes ne se traitent pas pareil,
  // et ce classement décide si un encaissement repart tout seul ou s'immobilise
  // en SYNC_ERROR. L'argent est déjà dans le tiroir, le reçu déjà imprimé.

  DioException dio422(String? detailCode, {String? message}) => DioException(
    requestOptions: RequestOptions(path: '/x'),
    response: Response(
      requestOptions: RequestOptions(path: '/x'),
      statusCode: 422,
      data: {'detailCode': ?detailCode, 'message': ?message},
    ),
  );

  test(
    'UNKNOWN_FEE_CODE → retry : l\'inscription n\'est pas encore remontée',
    () async {
      // Sur le chemin de synchro le serveur remappe par `studentId + feeCode` :
      // ne rien trouver veut le plus souvent dire que les créances de l'élève
      // n'existent pas encore côté serveur. Le figer immobiliserait de l'argent
      // qui n'avait qu'à attendre.
      when(
        () => api.commitPayment(any(), any()),
      ).thenThrow(dio422('UNKNOWN_FEE_CODE'));

      final result = await handlerWithGate(
        OutboxDependencyState.ready,
      ).dispatch(await pendingEntry());

      expect(result.outcome, OutboxDispatchOutcome.retry);
    },
  );

  for (final code in const [
    'ALLOCATION_SUM_MISMATCH',
    'CHARGE_CURRENCY_MISMATCH',
    'AMBIGUOUS_FEE_CODE',
    // Les deux refus de la déclaration d'encaissement (contrat du 2026-09-04).
    // Ils ne sont PAS transitoires : la même déclaration sera refusée à
    // l'identique au rejeu, et chaque tentative gaspillée rapproche du poison.
    'TENDER_SUM_MISMATCH',
    'UNKNOWN_TENDER_PIVOT',
  ]) {
    test('$code → failed : aucune attente ne le corrigera', () async {
      when(() => api.commitPayment(any(), any())).thenThrow(dio422(code));

      final result = await handlerWithGate(
        OutboxDependencyState.ready,
      ).dispatch(await pendingEntry());

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });
  }

  test(
    'un 422 sans detailCode reste failed — le défaut ne change pas',
    () async {
      when(() => api.commitPayment(any(), any())).thenThrow(dio422(null));

      final result = await handlerWithGate(
        OutboxDependencyState.ready,
      ).dispatch(await pendingEntry());

      expect(result.outcome, OutboxDispatchOutcome.failed);
    },
  );

  test('la raison porte le CODE machine, pas seulement le statut', () async {
    // Sans lui, toutes les causes d'un 422 se ressemblent, et la feuille de
    // reprise ne peut offrir qu'un « contactez le support » sur de l'argent
    // déjà encaissé.
    when(() => api.commitPayment(any(), any())).thenThrow(
      dio422('ALLOCATION_SUM_MISMATCH', message: 'Répartition incohérente'),
    );

    final result = await handlerWithGate(
      OutboxDependencyState.ready,
    ).dispatch(await pendingEntry());

    expect(result.error, contains('ALLOCATION_SUM_MISMATCH'));
    expect(result.error, contains('Répartition incohérente'));
  });
}
