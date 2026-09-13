import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_outbox_handler.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_withdrawal_outbox_handler.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _MockApi extends Mock implements ExpenseSyncApi {}

const _sent = '2026-09-03T09:00:00.000Z';
const _serverWithdrawal = '2026-09-02T08:00:00.000Z';

const _input = ExpenseInputDto(
  id: 'e-1',
  typeId: 't-elec',
  title: 'Facture SNEL',
  amountInCents: 38500000,
  currency: 'CDF',
  status: 'PAID',
  paidOn: '2026-09-03',
  expenseDate: '2026-09-03',
  fundingSource: 'CASH',
  clientUpdatedAt: _sent,
);

ExpenseSyncResponseDto _ack({String? deletedAt}) => ExpenseSyncResponseDto(
  expense: ExpenseDeltaDto(
    id: 'e-1',
    expenseNumber: 'DEP-0412',
    typeId: 't-elec',
    title: 'Facture SNEL',
    amountInCents: 38500000,
    currency: 'CDF',
    status: 'PAID',
    paidOn: '2026-09-03',
    expenseDate: '2026-09-03',
    clientUpdatedAt: _sent,
    deletedAt: deletedAt,
  ),
  lwwOutcome: 'APPLIED',
);

DioException _http(int? status, {Map<String, dynamic>? body}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: status,
          data: body,
        ),
);

void main() {
  late Database db;
  late _MockApi api;
  late ExpenseReadDao reader;
  late ExpenseSyncDao syncDao;
  late CurrentUserContext user;

  setUpAll(() {
    registerFallbackValue(const ExpenseSyncRequestDto(expense: _input));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    reader = ExpenseReadDao(db);
    syncDao = ExpenseSyncDao(db);
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
  });
  tearDown(() async => db.close());

  Future<void> seed({
    String? number,
    String clientUpdatedAt = _sent,
    String syncStatus = 'PENDING_SYNC',
  }) => db.insert(
    'expenses',
    ExpenseLocalModel(
      id: 'e-1',
      schoolId: 'school-1',
      expenseNumber: number,
      typeId: 't-elec',
      title: 'Facture SNEL',
      amountInCents: 38500000,
      currency: 'CDF',
      status: 'PAID',
      expenseDate: '2026-09-03',
      clientUpdatedAt: clientUpdatedAt,
      syncStatus: syncStatus,
    ).toMap(),
  );

  Future<ExpenseLocalModel?> row() => reader.find('e-1');

  group('contenu (EXPENSE)', () {
    ExpenseOutboxHandler handler() => ExpenseOutboxHandler(
      api: api,
      dao: syncDao,
      currentUser: user,
      extras: const {},
      now: () => 1,
    );
    OutboxEntry entry({String payload = '', String schoolId = 'school-1'}) =>
        OutboxEntry(
          id: ExpenseWriteDao.contentEntryId('e-1'),
          aggregateType: ExpenseWriteDao.aggregateType,
          aggregateId: 'e-1',
          operation: OutboxOperation.upsert,
          payload: payload.isEmpty
              ? jsonEncode(
                  const ExpenseSyncRequestDto(
                    expense: _input,
                    authorId: 'u-1',
                  ).toJson(),
                )
              : payload,
          schoolId: schoolId,
          createdAt: 0,
        );

    test('accusé → acked, la ligne est numérotée et synchronisée', () async {
      await seed();
      when(
        () => api.submitExpense(any(), any()),
      ).thenAnswer((_) async => _ack());

      final result = await handler().dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect((await row())!.expenseNumber, 'DEP-0412');
      expect((await row())!.syncStatus, 'SYNCED');
    });

    test('410 → la ligne s’efface, rien à rejouer', () async {
      await seed();
      when(() => api.submitExpense(any(), any())).thenThrow(_http(410));

      final result = await handler().dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await row(), isNull);
    });

    test('422 → échec terminal, la ligne porte le detailCode (A4)', () async {
      await seed();
      when(() => api.submitExpense(any(), any())).thenThrow(
        _http(
          422,
          body: {
            'detailCode': 'EXPENSE_DATE_IN_FUTURE',
            'message': 'date dans le futur',
          },
        ),
      );

      final result = await handler().dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(result.error, startsWith('EXPENSE_DATE_IN_FUTURE'));
      expect((await row())!.syncStatus, 'SYNC_ERROR');
      expect((await row())!.syncErrorCode, 'EXPENSE_DATE_IN_FUTURE');
    });

    test(
      '422 sur un état déjà corrigé en local → retry, jamais gelé',
      () async {
        await seed(clientUpdatedAt: '2026-09-03T09:05:00.000Z');
        when(() => api.submitExpense(any(), any())).thenThrow(_http(422));

        final result = await handler().dispatch(entry());

        expect(result.outcome, OutboxDispatchOutcome.retry);
        expect((await row())!.syncStatus, 'PENDING_SYNC');
      },
    );

    for (final status in [null, 409, 503]) {
      test('transitoire ($status) → retry', () async {
        await seed();
        when(() => api.submitExpense(any(), any())).thenThrow(_http(status));
        final result = await handler().dispatch(entry());
        expect(result.outcome, OutboxDispatchOutcome.retry);
      });
    }

    test('payload illisible → failed, sans appel réseau', () async {
      final result = await handler().dispatch(
        entry(payload: '{"pas": "une dépense"}'),
      );
      expect(result.outcome, OutboxDispatchOutcome.failed);
      verifyNever(() => api.submitExpense(any(), any()));
    });

    test('dépense d’une autre école du poste → blocked, sans appel', () async {
      await seed();
      final result = await handler().dispatch(entry(schoolId: 'school-2'));
      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.submitExpense(any(), any()));
    });
  });

  group('retrait (EXPENSE_WITHDRAWAL)', () {
    ExpenseWithdrawalOutboxHandler handler() => ExpenseWithdrawalOutboxHandler(
      api: api,
      reader: reader,
      writer: ExpenseWriteDao(db),
      dao: syncDao,
      currentUser: user,
      extras: const {},
      now: () => 1,
    );
    OutboxEntry entry({bool deleted = true, String schoolId = 'school-1'}) =>
        OutboxEntry(
          id: ExpenseWriteDao.withdrawalEntryId('e-1'),
          aggregateType: ExpenseWriteDao.withdrawalAggregateType,
          aggregateId: 'e-1',
          operation: OutboxOperation.update,
          payload: jsonEncode(
            ExpenseWithdrawalPayload(
              expenseId: 'e-1',
              deleted: deleted,
              changedAt: _sent,
              authorId: 'u-1',
            ).toJson(),
          ),
          schoolId: schoolId,
          createdAt: 0,
        );

    Future<void> withdrawnLocally({
      String? number = 'DEP-0412',
      String syncStatus = 'PENDING_SYNC',
    }) async {
      await seed(number: number, syncStatus: syncStatus);
      await db.update('expenses', {
        'deleted_at': _sent,
        'withdrawal_pending_at': _sent,
      });
    }

    test('dépense pas encore numérotée → blocked, sans appel', () async {
      await withdrawnLocally(number: null);
      final result = await handler().dispatch(entry());
      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.setWithdrawn(any(), any(), any()));
    });

    test(
      'jamais acceptée, dernier envoi refusé : le retrait se règle sur le '
      'poste seul — il n’attendra pas un numéro qui ne viendra pas',
      () async {
        await withdrawnLocally(number: null, syncStatus: 'SYNC_ERROR');
        await OutboxDao(db).enqueue(
          OutboxEntry(
            id: ExpenseWriteDao.contentEntryId('e-1'),
            aggregateType: ExpenseWriteDao.aggregateType,
            aggregateId: 'e-1',
            operation: OutboxOperation.upsert,
            payload: '{}',
            schoolId: 'school-1',
            createdAt: 0,
          ),
        );
        await OutboxDao(db).markSyncError(
          ExpenseWriteDao.contentEntryId('e-1'),
          'UNKNOWN_EXPENSE_TYPE',
        );

        final result = await handler().dispatch(entry());

        expect(result.outcome, OutboxDispatchOutcome.acked);
        verifyNever(() => api.setWithdrawn(any(), any(), any()));
        final r = (await row())!;
        expect(r.deletedAt, _sent);
        expect(r.withdrawalPendingAt, isNull);
        final content = await db.query('outbox');
        expect(content.single['status'], OutboxStatus.acked.dbValue);
      },
    );

    test('geste déjà réglé (plus en attente sur la ligne) → acked, sans '
        'appel', () async {
      await seed(number: 'DEP-0412');
      final result = await handler().dispatch(entry());
      expect(result.outcome, OutboxDispatchOutcome.acked);
      verifyNever(() => api.setWithdrawn(any(), any(), any()));
    });

    test('dépense d’une autre école du poste → blocked, sans appel', () async {
      await withdrawnLocally();
      final result = await handler().dispatch(entry(schoolId: 'school-2'));
      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.setWithdrawn(any(), any(), any()));
    });

    test(
      'accusé → retrait posé, attente levée ; le chemin porte l’id',
      () async {
        await withdrawnLocally();
        when(
          () => api.setWithdrawn(any(), any(), any()),
        ).thenAnswer((_) async => _ack(deletedAt: _sent));

        final result = await handler().dispatch(entry());

        expect(result.outcome, OutboxDispatchOutcome.acked);
        final captured = verify(
          () => api.setWithdrawn(any(), captureAny(), captureAny()),
        ).captured;
        expect(captured[0], 'e-1');
        expect(captured[1], {
          'deleted': true,
          'changedAt': _sent,
          'authorId': 'u-1',
        });
        final r = (await row())!;
        expect(r.withdrawalPendingAt, isNull);
        expect(r.serverDeletedAt, _sent);
      },
    );

    test('403 → échec terminal, et la ligne revient au registre', () async {
      await withdrawnLocally();
      when(() => api.setWithdrawn(any(), any(), any())).thenThrow(_http(403));

      final result = await handler().dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect((await row())!.deletedAt, isNull);
    });

    test('restauration refusée : la ligne revient à ce que le SERVEUR sait, '
        'pas à un état deviné', () async {
      // Retirée côté serveur, restaurée ici (« Annuler ») : le refus de la
      // restauration la laisse retirée, comme le serveur la voit.
      await seed(number: 'DEP-0412');
      await db.update('expenses', {
        'withdrawal_pending_at': _sent,
        'server_deleted_at': _serverWithdrawal,
      });
      when(() => api.setWithdrawn(any(), any(), any())).thenThrow(_http(403));

      final result = await handler().dispatch(entry(deleted: false));

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final r = (await row())!;
      expect(r.deletedAt, _serverWithdrawal);
      expect(r.withdrawalPendingAt, isNull);
    });

    test('404 sur une dépense numérotée : le geste n’a plus d’objet, '
        'l’attente se lève', () async {
      await withdrawnLocally();
      when(() => api.setWithdrawn(any(), any(), any())).thenThrow(_http(404));

      final result = await handler().dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final r = (await row())!;
      expect(r.withdrawalPendingAt, isNull, reason: 'le pull reprend la main');
      expect(r.deletedAt, _sent, reason: 'le geste local reste');
    });

    test('ligne disparue → acked sans appel', () async {
      final result = await handler().dispatch(entry());
      expect(result.outcome, OutboxDispatchOutcome.acked);
      verifyNever(() => api.setWithdrawn(any(), any(), any()));
    });
  });
}
