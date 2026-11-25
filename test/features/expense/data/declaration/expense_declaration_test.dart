import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_cipher.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_declaration_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_gesture_outbox_handler.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_gesture_payload.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'dart:convert';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_type_dao.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_declaration_repository_impl.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_outbox_handler.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_payload.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_blobs.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_server_message_ids.dart';
import 'package:school_app_flutter/features/treasury/data/local/cash_pending_probe_sql.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../../helpers/permission_denial.dart';
import '../../../offline_full_db.dart';

class _MockApi extends Mock implements ExpenseDeclarationApi {}

class _MockSyncApi extends Mock implements ExpenseSyncApi {}

class _UuidIds implements IdGenerator {
  @override
  String newId() => const Uuid().v4();
}

class _FakeKeyService implements BlobKeyService {
  @override
  String get storageKey => 'test';

  @override
  Future<BlobKey> getOrCreate() async => BlobKey(
    bytes: Uint8List.fromList(List<int>.generate(32, (i) => i)),
    createdNow: false,
  );

  @override
  Future<void> destroy() async {}
}

DioException _http(int? status, {String? detailCode}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: status,
          data: detailCode == null ? null : {'detailCode': detailCode},
        ),
);

/// DEP-18 — déclarer : l'écriture sur le poste, l'envoi, et ce qu'un refus
/// laisse derrière lui quand l'argent est déjà sorti.
void main() {
  late Database db;
  late Directory base;
  late ExpenseVoucherBlobs blobs;
  late ExpenseDeclarationDao dao;
  late ExpenseDeclarationRepositoryImpl repository;
  late _MockApi api;
  late ExpenseDeclarationOutboxHandler handler;
  late DateTime now;

  final photo = Uint8List.fromList(List<int>.generate(64, (i) => i));

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      ExpenseDeclarationPayload(
        expense: ExpenseInputDto.fromJson(const {
          'id': 'x',
          'typeId': 'x',
          'title': 'x',
          'amountInCents': 1,
          'currency': 'USD',
          'status': 'PAID',
          'expenseDate': '2026-01-01',
          'clientUpdatedAt': '2026-01-01T00:00:00.000Z',
        }),
        disbursedAt: 'x',
        messageId: 'x',
        messageBody: '',
        authorId: 'x',
        voucherContentType: 'image/jpeg',
      ),
    );
  });

  setUp(() async {
    db = await openFullOfflineDb();
    base = await Directory.systemTemp.createTemp('expense_declaration_test');
    blobs = ExpenseVoucherBlobs(
      EncryptedBlobStore(
        directoryName: 'expense_vouchers',
        keyService: _FakeKeyService(),
        cipher: runBlobCipherTask,
        baseDirectory: () async => base,
      ),
    );
    for (final (id, code) in [('t-fuel', 'FUEL'), ('t-adv', 'STAFF_ADVANCE')]) {
      await db.insert('ref_expense_types', {
        'id': id,
        'school_id': 'school-1',
        'code': code,
        'label': code,
        'short_label': code,
        'icon': 'x',
        'color': '#000000',
        'soft_color': '#ffffff',
        'default_currency': 'USD',
      });
    }
    final user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    now = DateTime.utc(2026, 11, 25, 9, 14);
    dao = ExpenseDeclarationDao(db);
    repository = ExpenseDeclarationRepositoryImpl(
      dao: dao,
      types: ExpenseTypeDao(db),
      blobs: blobs,
      currentUser: user,
      ids: _UuidIds(),
      now: () => now,
    );
    api = _MockApi();
    handler = ExpenseDeclarationOutboxHandler(
      api: api,
      dao: dao,
      blobs: blobs,
      currentUser: user,
      extras: const {},
      now: () => now.millisecondsSinceEpoch,
    );
  });

  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  ExpenseDeclarationDraft draft({
    String typeId = 't-fuel',
    DateTime? disbursedAt,
    Uint8List? voucher,
    bool visaOnDeclare = false,
    String? replacing,
  }) => ExpenseDeclarationDraft(
    typeId: typeId,
    title: 'Carburant groupe',
    amountInCents: 4500,
    currency: 'usd',
    disbursedAt: disbursedAt ?? DateTime.utc(2026, 11, 25, 9, 12),
    note: 'Accord du promoteur par WhatsApp',
    voucherBytes: voucher ?? photo,
    voucherContentType: 'image/jpeg',
    visaOnDeclare: visaOnDeclare,
    recordedByName: 'La caissière',
    replacing: replacing,
  );

  Future<Expense> declare([ExpenseDeclarationDraft? d]) async =>
      (await repository.declare(d ?? draft())).getOrElse(() => throw 'Left');

  Future<Expense> reload(String id) async =>
      (await ExpenseReadDao(db).find(id))!.toEntity()!;

  group('déclarer sur le poste', () {
    test(
      'naît payée, à viser, avec sa photo, son message et son entrée',
      () async {
        final expense = await declare();

        expect(expense.status, ExpenseStatus.paid);
        expect(expense.isDeclaration, isTrue);
        expect(expense.visaStatus, ExpenseVisaStatus.pending);
        expect(expense.paidOn, DateTime(2026, 11, 25));
        expect(expense.expenseDate, DateTime(2026, 11, 25));
        expect(expense.voucher?.sizeBytes, photo.length);
        expect(await blobs.isOnDevice(expense.id), isTrue);

        final thread = await ExpenseMessageDao(
          db,
        ).threadFor(expense.id, schoolId: 'school-1');
        expect(thread.single.act, 'DECLARATION');
        expect(thread.single.body, 'Accord du promoteur par WhatsApp');
        final entry = await OutboxDao(
          db,
        ).byId(ExpenseDeclarationDao.entryId(expense.id));
        expect(entry, isNotNull);
        expect(
          await ExpenseMessageDao(db).oldestPendingId(expense.id),
          thread.single.id,
          reason: 'la déclaration ordonne les gestes qui suivront (F38)',
        );
      },
    );

    test('le jour est celui de Kinshasa, pas celui de la tablette', () async {
      now = DateTime.utc(2026, 11, 25, 23, 50);
      final expense = await declare(
        draft(disbursedAt: DateTime.utc(2026, 11, 25, 23, 30)),
      );

      expect(expense.paidOn, DateTime(2026, 11, 26));
      expect(expense.expenseDate, DateTime(2026, 11, 26));
    });

    test('une heure future est bornée à maintenant', () async {
      final expense = await declare(
        draft(disbursedAt: now.add(const Duration(hours: 3))),
      );

      expect(expense.disbursedAt, now);
    });

    test('visa d’office : visée par le déclarant, VISA d’id uuid5', () async {
      final expense = await declare(draft(visaOnDeclare: true));

      expect(expense.visaStatus, ExpenseVisaStatus.visaed);
      expect(expense.visaById, 'u-1');
      final thread = await ExpenseMessageDao(
        db,
      ).threadFor(expense.id, schoolId: 'school-1');
      expect(thread.map((m) => m.act), ['DECLARATION', 'VISA']);
      expect(thread.last.id, ExpenseServerMessageIds.visa(expense.id));
    });

    test('refusées sur le poste : avance, sans photo, mauvais type', () async {
      Future<Failure> failureOf(ExpenseDeclarationDraft d) async =>
          (await repository.declare(d)).fold((f) => f, (_) => throw 'Right');

      expect(await failureOf(draft(typeId: 't-adv')), isA<ValidationFailure>());
      expect(
        await failureOf(draft(voucher: Uint8List(0))),
        isA<ValidationFailure>(),
      );
      expect(await failureOf(draft(typeId: 't-?')), isA<ValidationFailure>());
      expect(await db.query('expenses'), isEmpty);
      expect(await db.query(OutboxDao.table), isEmpty);
    });
  });

  group('l’envoi', () {
    Future<OutboxDispatchResult> dispatch(Expense expense) async =>
        handler.dispatch(
          (await OutboxDao(
            db,
          ).byId(ExpenseDeclarationDao.entryId(expense.id)))!,
        );

    ExpenseSyncResponseDto ack(
      Expense expense, {
      required List<String> messageIds,
      String outcome = 'APPLIED',
    }) => ExpenseSyncResponseDto(
      lwwOutcome: outcome,
      expense: ExpenseDeltaDto.tryParse({
        'id': expense.id,
        'expenseNumber': 'DEP-0142',
        'typeId': 't-fuel',
        'title': 'Carburant groupe',
        'amountInCents': 4500,
        'currency': 'USD',
        'status': 'PAID',
        'paidOn': '2026-11-25',
        'paidAt': '2026-11-25T09:12:00Z',
        'expenseDate': '2026-11-25',
        'clientUpdatedAt': '2026-11-25T09:14:00Z',
        'mode': 'DECLARATION',
        'visaStatus': 'PENDING',
        'cashDay': '2026-11-25',
        'afterClosure': false,
        'voucher': {
          'id': expense.id,
          'contentType': 'image/jpeg',
          'sizeBytes': 64,
          'uploadedAt': '2026-11-25T09:15:00Z',
        },
        'messages': [
          for (final id in messageIds)
            {
              'id': id,
              'body': 'Accord du promoteur par WhatsApp',
              'act': 'DECLARATION',
              'createdAt': '2026-11-25T09:14:00Z',
              'authorId': 'u-1',
            },
        ],
      })!,
    );

    test('accusée : numérotée, accusée, son message aussi', () async {
      final expense = await declare();
      final messageId = (await ExpenseMessageDao(
        db,
      ).oldestPendingId(expense.id))!;
      when(
        () => api.submit(any(), any(), any()),
      ).thenAnswer((_) async => ack(expense, messageIds: [messageId]));

      final result = await dispatch(expense);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final after = await reload(expense.id);
      expect(after.number, 'DEP-0142');
      expect(after.syncState, ExpenseSyncState.synced);
      expect(after.cashDay, DateTime(2026, 11, 25));
      expect(await ExpenseMessageDao(db).oldestPendingId(expense.id), isNull);
    });

    test(
      'un rejeu porteur d’un autre message : celui du serveur fait foi',
      () async {
        final expense = await declare();
        when(() => api.submit(any(), any(), any())).thenAnswer(
          (_) async =>
              ack(expense, messageIds: ['m-serveur'], outcome: 'SUPERSEDED'),
        );

        await dispatch(expense);

        final thread = await ExpenseMessageDao(
          db,
        ).threadFor(expense.id, schoolId: 'school-1');
        expect(thread.map((m) => m.id), ['m-serveur']);
      },
    );

    test(
      'refus terminal : jamais effacée, à régulariser, hors totaux',
      () async {
        final expense = await declare();
        when(
          () => api.submit(any(), any(), any()),
        ).thenThrow(_http(422, detailCode: 'UNKNOWN_EXPENSE_TYPE'));

        final result = await dispatch(expense);

        expect(result.outcome, OutboxDispatchOutcome.failed);
        final after = await reload(expense.id);
        expect(after.isDeclarationToRegularize, isTrue);
        expect(
          after.isFirm,
          isFalse,
          reason: 'le serveur ne l’a jamais comptée',
        );
        expect(after.syncErrorCode, 'UNKNOWN_EXPENSE_TYPE');
        expect(await ExpenseMessageDao(db).oldestPendingId(expense.id), isNull);
      },
    );

    test('un 410 ne l’efface pas non plus : l’argent est sorti', () async {
      final expense = await declare();
      when(() => api.submit(any(), any(), any())).thenThrow(_http(410));

      await dispatch(expense);

      expect(await ExpenseReadDao(db).find(expense.id), isNotNull);
    });

    test('un droit retiré retient l’entrée au lieu de la perdre', () async {
      final expense = await declare();
      when(
        () => api.submit(any(), any(), any()),
      ).thenThrow(permissionDenial403());

      final result = await dispatch(expense);

      expect(result.permissionDenied, isTrue);
      expect((await reload(expense.id)).isRejected, isFalse);
    });

    test('réseau et 5xx se rejouent', () async {
      final expense = await declare();
      when(() => api.submit(any(), any(), any())).thenThrow(_http(null));
      expect((await dispatch(expense)).outcome, OutboxDispatchOutcome.retry);
      when(() => api.submit(any(), any(), any())).thenThrow(_http(503));
      expect((await dispatch(expense)).outcome, OutboxDispatchOutcome.retry);
    });

    test(
      'photo perdue : la déclaration ne peut plus partir, et le dit',
      () async {
        final expense = await declare();
        await blobs.delete(expense.id);

        final result = await dispatch(expense);

        expect(result.outcome, OutboxDispatchOutcome.failed);
        expect(
          (await reload(expense.id)).syncErrorCode,
          ExpenseDeclarationOutboxHandler.bytesLostCode,
        );
        verifyNever(() => api.submit(any(), any(), any()));
      },
    );
  });

  test('redéclarer abandonne la refusée : jamais les deux comptées', () async {
    final refused = await declare();
    await dao.markRefused(refused.id, code: 'X', reason: 'X', nowMs: 0);

    final again = await declare(draft(replacing: refused.id));

    expect((await reload(refused.id)).isWithdrawn, isTrue);
    expect((await reload(again.id)).isFirm, isTrue);
  });

  group('la clôture de caisse (F46)', () {
    test('une déclaration en espèces pas encore partie la retient', () async {
      final probe = CashPendingProbeSql(db);
      expect(await probe.pendingFor(TreasuryCurrency.usd), 0);

      final expense = await declare();
      expect(await probe.pendingFor(TreasuryCurrency.usd), 1);

      await dao.markRefused(expense.id, code: 'X', reason: 'X', nowMs: 0);
      await OutboxDao(
        db,
      ).markSyncError(ExpenseDeclarationDao.entryId(expense.id), 'X');
      expect(
        await probe.pendingFor(TreasuryCurrency.usd),
        0,
        reason: 'à régulariser, elle ne partira plus sans un geste',
      );
    });
  });

  /// Un geste écrit après la déclaration, comme le dépôt l'écrirait.
  Future<OutboxEntry> gesture(
    Expense expense,
    ExpenseGesture g, {
    required DateTime at,
  }) async {
    const messageId = 'm-geste';
    final payload = ExpenseGesturePayload(
      expenseId: expense.id,
      gesture: g,
      messageId: messageId,
      body: '',
      decidedAt: at.toIso8601String(),
      authorId: 'u-1',
    );
    final entry = OutboxEntry(
      id: ExpenseWriteDao.gestureEntryId(messageId),
      aggregateType: ExpenseWriteDao.gestureAggregateType,
      aggregateId: expense.id,
      operation: OutboxOperation.create,
      payload: jsonEncode(payload.toJson()),
      schoolId: 'school-1',
      createdAt: at.millisecondsSinceEpoch,
    );
    await ExpenseMessageDao(db).appendGesture(
      ExpenseMessageLocalModel.at(
        at,
        id: messageId,
        schoolId: 'school-1',
        expenseId: expense.id,
        body: '',
        act: g.act,
        authorId: 'u-1',
      ),
      entry: entry,
    );
    return entry;
  }

  test('un visa attend la déclaration qui le précède (F38)', () async {
    final expense = await declare();
    final entry = await gesture(
      expense,
      ExpenseGesture.visa,
      at: now.add(const Duration(minutes: 1)),
    );
    final syncApi = _MockSyncApi();

    final result = await ExpenseGestureOutboxHandler(
      api: syncApi,
      dao: ExpenseSyncDao(db),
      messages: ExpenseMessageDao(db),
      currentUser: CurrentUserContext()..set('u-1', schoolId: 'school-1'),
      extras: const {},
    ).dispatch(entry);

    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyZeroInteractions(syncApi);
  });

  test(
    'une annulation en espèces pas encore partie retient la clôture',
    () async {
      final expense = await declare();
      // La déclaration est partie et accusée ; seule l'annulation attend.
      await OutboxDao(db).markAcked(ExpenseDeclarationDao.entryId(expense.id));
      await db.update(
        'expense_messages',
        {'sync_status': ExpenseSyncState.synced.dbValue},
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );
      final probe = CashPendingProbeSql(db);
      expect(await probe.pendingFor(TreasuryCurrency.usd), 0);

      await gesture(
        expense,
        ExpenseGesture.reopen,
        at: now.add(const Duration(minutes: 1)),
      );

      expect(await probe.pendingFor(TreasuryCurrency.usd), 1);
    },
  );
}
