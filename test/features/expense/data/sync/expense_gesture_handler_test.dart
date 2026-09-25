import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_sync_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_error_codes.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_gesture_outbox_handler.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_gesture_payload.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _MockApi extends Mock implements ExpenseSyncApi {}

/// La remontée d'un geste : son ordre, et la lecture des deux 409.
///
/// Ce que ce fichier protège, c'est l'invariant que le socle NE tient PAS —
/// le moteur d'outbox ne lit jamais `aggregate_id`, poursuit après un `retry`,
/// et son backoff retire une entrée de la course pendant 1 à 256 s. L'ordre
/// est à la charge du handler, et le registre d'ordre est le fil.
void main() {
  late Database db;
  late _MockApi api;
  late ExpenseSyncDao syncDao;
  late ExpenseMessageDao messages;
  late ExpenseReadDao reader;
  late CurrentUserContext user;

  ExpenseDeltaDto canonical({
    String status = 'APPROVED',
    String? decidedByName = 'Mbala Thérèse',
    List<ExpenseMessageDeltaDto> thread = const [],
  }) => ExpenseDeltaDto(
    id: 'e-1',
    expenseNumber: 'DEP-0412',
    typeId: 't-elec',
    title: 'Facture SNEL',
    amountInCents: 38500000,
    currency: 'CDF',
    status: status,
    expenseDate: '2026-09-03',
    clientUpdatedAt: '2026-09-03T09:00:00.000Z',
    decidedByName: decidedByName,
    decidedAt: '2026-09-04T08:00:00.000Z',
    messages: thread,
  );

  DioException http(int status, {Map<String, dynamic>? body}) => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: status,
      data: body,
    ),
  );

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    syncDao = ExpenseSyncDao(db);
    messages = ExpenseMessageDao(db);
    reader = ExpenseReadDao(db);
    user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    await db.insert(
      'expenses',
      ExpenseLocalModel(
        id: 'e-1',
        schoolId: 'school-1',
        expenseNumber: 'DEP-0412',
        typeId: 't-elec',
        title: 'Facture SNEL',
        amountInCents: 38500000,
        currency: 'CDF',
        status: 'PENDING',
        expenseDate: '2026-09-03',
        clientUpdatedAt: '2026-09-03T09:00:00.000Z',
        syncStatus: ExpenseSyncState.synced.dbValue,
      ).toMap(),
    );
  });
  tearDown(() => db.close());

  ExpenseGestureOutboxHandler handler() => ExpenseGestureOutboxHandler(
    api: api,
    dao: syncDao,
    messages: messages,
    currentUser: user,
    extras: const {},
    now: () => 42,
  );

  /// Écrit un message local en attente, comme le ferait un geste.
  Future<void> seedMessage(
    String id, {
    required String at,
    ExpenseSyncState state = ExpenseSyncState.pending,
  }) => db.insert(
    'expense_messages',
    ExpenseMessageLocalModel(
      id: id,
      schoolId: 'school-1',
      expenseId: 'e-1',
      body: '',
      act: 'APPROVAL',
      authorId: 'u-1',
      createdAt: at,
      syncStatus: state.dbValue,
    ).toMap(),
  );

  OutboxEntry entry(
    String messageId, {
    ExpenseGesture gesture = ExpenseGesture.approve,
    String at = '2026-09-04T08:00:00.000Z',
  }) => OutboxEntry(
    id: ExpenseWriteDao.gestureEntryId(messageId),
    aggregateType: ExpenseWriteDao.gestureAggregateType,
    aggregateId: 'e-1',
    operation: OutboxOperation.create,
    payload: jsonEncode(
      ExpenseGesturePayload(
        expenseId: 'e-1',
        gesture: gesture,
        messageId: messageId,
        body: '',
        decidedAt: at,
        authorId: 'u-1',
      ).toJson(),
    ),
    schoolId: 'school-1',
    createdAt: 1,
  );

  Future<ExpenseSyncState> messageState(String id) async {
    final rows = await db.query(
      'expense_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
    return ExpenseSyncState.fromDb(rows.single['sync_status'] as String?);
  }

  group('la garde d\'ordre (F31)', () {
    test('le geste le plus ancien part', () async {
      await seedMessage('m-1', at: '2026-09-04T08:00:00.000Z');
      await seedMessage('m-2', at: '2026-09-04T09:00:00.000Z');
      when(() => api.decideExpense(any(), any(), any())).thenAnswer(
        (_) async =>
            ExpenseSyncResponseDto(expense: canonical(), lwwOutcome: 'APPLIED'),
      );

      final result = await handler().dispatch(entry('m-1'));

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await messageState('m-1'), ExpenseSyncState.synced);
    });

    test('un geste EN AVANCE attend — sans consommer de tentative', () async {
      // C'est exactement ce que fait le backoff : il retire le prédécesseur de
      // la course pendant 1 à 256 s, et le suivant se présente le premier.
      await seedMessage('m-1', at: '2026-09-04T08:00:00.000Z');
      await seedMessage('m-2', at: '2026-09-04T09:00:00.000Z');

      final result = await handler().dispatch(entry('m-2'));

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.decideExpense(any(), any(), any()));
      // `blocked` n'empoisonne jamais : le message reste en attente.
      expect(await messageState('m-2'), ExpenseSyncState.pending);
    });

    test('une séquence de trois gestes part DANS L\'ORDRE', () async {
      await seedMessage('m-1', at: '2026-09-04T08:00:00.000Z');
      await seedMessage('m-2', at: '2026-09-04T09:00:00.000Z');
      await seedMessage('m-3', at: '2026-09-04T10:00:00.000Z');
      final sent = <String>[];
      when(() => api.decideExpense(any(), any(), any())).thenAnswer((
        call,
      ) async {
        final body = call.positionalArguments[2] as Map<String, dynamic>;
        sent.add((body['message'] as Map)['id'] as String);
        return ExpenseSyncResponseDto(
          expense: canonical(),
          lwwOutcome: 'APPLIED',
        );
      });

      // Le moteur les présente à l'envers — il ne promet aucun ordre.
      for (final id in ['m-3', 'm-2', 'm-1']) {
        await handler().dispatch(entry(id));
      }
      // Puis chacun rejoue, comme après un backoff.
      for (final id in ['m-3', 'm-2']) {
        await handler().dispatch(entry(id));
      }
      await handler().dispatch(entry('m-3'));

      expect(sent, ['m-1', 'm-2', 'm-3']);
    });

    test('un geste qui échoue condamne SUR-LE-CHAMP la suite qu\'il '
        'portait', () async {
      // ⚠️ L'échappatoire, sans laquelle la garde devient un gel : `blocked`
      // n'incrémente rien et ne s'empoisonne jamais, donc un prédécesseur
      // refusé pour de bon bloquerait la demande pour toujours.
      await seedMessage('m-1', at: '2026-09-04T08:00:00.000Z');
      await seedMessage('m-2', at: '2026-09-04T09:00:00.000Z');
      when(() => api.decideExpense(any(), any(), any())).thenThrow(
        http(
          422,
          body: {'detailCode': ExpenseErrorCodes.selfApprovalForbidden},
        ),
      );

      await handler().dispatch(entry('m-1'));

      expect(await messageState('m-1'), ExpenseSyncState.rejected);
      // Payer une demande dont l'approbation a été refusée n'a aucun sens.
      expect(await messageState('m-2'), ExpenseSyncState.rejected);
    });

    test('un geste condamné échoue au lieu d\'attendre son tour', () async {
      await seedMessage(
        'm-2',
        at: '2026-09-04T09:00:00.000Z',
        state: ExpenseSyncState.rejected,
      );

      final result = await handler().dispatch(entry('m-2'));

      expect(result.outcome, OutboxDispatchOutcome.failed);
      verifyNever(() => api.decideExpense(any(), any(), any()));
    });

    test('🔴 un geste NEUF n\'est pas condamné par un mort plus ancien — '
        'sinon le premier refus gèlerait la demande pour toujours', () async {
      // Le scénario de réparation : l'agent voit « à corriger », et agit de
      // nouveau. Son geste est le plus ancien EN ATTENTE, donc il part.
      await seedMessage(
        'm-1',
        at: '2026-09-04T08:00:00.000Z',
        state: ExpenseSyncState.rejected,
      );
      await seedMessage('m-neuf', at: '2026-09-05T08:00:00.000Z');
      when(() => api.decideExpense(any(), any(), any())).thenAnswer(
        (_) async =>
            ExpenseSyncResponseDto(expense: canonical(), lwwOutcome: 'APPLIED'),
      );

      final result = await handler().dispatch(entry('m-neuf'));

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(await messageState('m-neuf'), ExpenseSyncState.synced);
    });

    test('un fil entièrement accusé ne bloque personne', () async {
      await seedMessage(
        'm-1',
        at: '2026-09-04T08:00:00.000Z',
        state: ExpenseSyncState.synced,
      );
      when(() => api.decideExpense(any(), any(), any())).thenAnswer(
        (_) async =>
            ExpenseSyncResponseDto(expense: canonical(), lwwOutcome: 'APPLIED'),
      );

      final result = await handler().dispatch(entry('m-1'));

      expect(result.outcome, OutboxDispatchOutcome.acked);
    });
  });

  group('les deux 409, aux conduites OPPOSÉES (F34)', () {
    setUp(() => seedMessage('m-1', at: '2026-09-04T08:00:00.000Z'));

    test('DECISION_ALREADY_TAKEN : se réaligner, ne JAMAIS rejouer', () async {
      when(() => api.decideExpense(any(), any(), any())).thenThrow(
        http(
          409,
          body: {
            'detailCode': ExpenseErrorCodes.decisionAlreadyTaken,
            'message': 'DEP-0412 a déjà été approuvée.',
            'expense': {
              'id': 'e-1',
              'expenseNumber': 'DEP-0412',
              'typeId': 't-elec',
              'title': 'Facture SNEL',
              'amountInCents': 38500000,
              'currency': 'CDF',
              'status': 'APPROVED',
              'expenseDate': '2026-09-03',
              'clientUpdatedAt': '2026-09-03T09:00:00.000Z',
              'decidedByName': 'Mbala Thérèse',
              'decidedAt': '2026-09-04T07:00:00.000Z',
            },
          },
        ),
      );

      final result = await handler().dispatch(entry('m-1'));

      // Rejouer écraserait la décision d'un collègue.
      expect(result.outcome, OutboxDispatchOutcome.failed);
      final row = await reader.find('e-1');
      expect(row!.status, 'APPROVED');
      expect(row.decidedByName, 'Mbala Thérèse');
      expect(await messageState('m-1'), ExpenseSyncState.rejected);
    });

    test('TRANSITION_OUT_OF_ORDER : rejouer, ne RIEN réaligner', () async {
      when(() => api.decideExpense(any(), any(), any())).thenThrow(
        http(
          409,
          body: {
            'detailCode': ExpenseErrorCodes.transitionOutOfOrder,
            'message': 'Le prédécesseur n\'est pas arrivé.',
          },
        ),
      );

      final result = await handler().dispatch(entry('m-1'));

      expect(result.outcome, OutboxDispatchOutcome.retry);
      // La ligne locale est JUSTE : c'est le serveur qui n'a pas vu ce qui
      // vient avant. Rien n'a été touché, et le message reste en attente.
      expect((await reader.find('e-1'))!.status, 'PENDING');
      expect(await messageState('m-1'), ExpenseSyncState.pending);
    });

    test(
      'un 409 SANS detailCode reste la course d\'antan : on rejoue',
      () async {
        when(() => api.decideExpense(any(), any(), any())).thenThrow(http(409));

        final result = await handler().dispatch(entry('m-1'));

        expect(result.outcome, OutboxDispatchOutcome.retry);
      },
    );
  });

  group('les refus terminaux', () {
    setUp(() => seedMessage('m-1', at: '2026-09-04T08:00:00.000Z'));

    test(
      '422 SELF_APPROVAL_FORBIDDEN : la ligne passe « à corriger »',
      () async {
        when(() => api.decideExpense(any(), any(), any())).thenThrow(
          http(
            422,
            body: {'detailCode': ExpenseErrorCodes.selfApprovalForbidden},
          ),
        );

        final result = await handler().dispatch(entry('m-1'));

        expect(result.outcome, OutboxDispatchOutcome.failed);
        final row = await reader.find('e-1');
        expect(row!.syncStatus, ExpenseSyncState.rejected.dbValue);
        expect(row.syncErrorCode, ExpenseErrorCodes.selfApprovalForbidden);
        expect(await messageState('m-1'), ExpenseSyncState.rejected);
      },
    );

    test('un 5xx se rejoue et ne marque RIEN', () async {
      when(() => api.decideExpense(any(), any(), any())).thenThrow(http(503));

      final result = await handler().dispatch(entry('m-1'));

      expect(result.outcome, OutboxDispatchOutcome.retry);
      expect(
        (await reader.find('e-1'))!.syncStatus,
        ExpenseSyncState.synced.dbValue,
      );
    });

    test(
      'un COMMENTAIRE refusé ne rend pas la dépense « à corriger »',
      () async {
        // Il n'y a rien à corriger dans une demande parce qu'un mot n'a pas pu
        // s'écrire — la ligne n'a même pas bougé.
        when(
          () => api.commentExpense(any(), any(), any()),
        ).thenThrow(http(403));

        final result = await handler().dispatch(
          entry('m-1', gesture: ExpenseGesture.comment),
        );

        expect(result.outcome, OutboxDispatchOutcome.failed);
        expect(await messageState('m-1'), ExpenseSyncState.rejected);
        expect(
          (await reader.find('e-1'))!.syncStatus,
          ExpenseSyncState.synced.dbValue,
        );
      },
    );

    test('un geste qui PASSE lève le « à corriger » posé par un geste '
        'précédent', () async {
      await syncDao.markGestureRejected(
        'e-1',
        code: ExpenseErrorCodes.transitionOutOfOrder,
        reason: 'hors séquence',
        nowMs: 1,
      );
      when(() => api.decideExpense(any(), any(), any())).thenAnswer(
        (_) async =>
            ExpenseSyncResponseDto(expense: canonical(), lwwOutcome: 'APPLIED'),
      );

      await handler().dispatch(entry('m-1'));

      final row = await reader.find('e-1');
      expect(row!.syncStatus, ExpenseSyncState.synced.dbValue);
      expect(row.syncErrorCode, isNull);
    });

    test('mais il ne lève PAS un refus de CONTENU : celui-là attend une '
        'vraie correction', () async {
      await syncDao.markGestureRejected(
        'e-1',
        code: ExpenseErrorCodes.unknownExpenseType,
        reason: 'type inconnu',
        nowMs: 1,
      );
      when(() => api.decideExpense(any(), any(), any())).thenAnswer(
        (_) async =>
            ExpenseSyncResponseDto(expense: canonical(), lwwOutcome: 'APPLIED'),
      );

      await handler().dispatch(entry('m-1'));

      final row = await reader.find('e-1');
      expect(row!.syncStatus, ExpenseSyncState.rejected.dbValue);
      expect(row.syncErrorCode, ExpenseErrorCodes.unknownExpenseType);
    });

    test('un payload illisible ne se répare pas en le rejouant', () async {
      final result = await handler().dispatch(
        const OutboxEntry(
          id: 'EXPENSE_GESTURE:x',
          aggregateType: ExpenseWriteDao.gestureAggregateType,
          aggregateId: 'e-1',
          operation: OutboxOperation.create,
          payload: '{ pas du json',
          schoolId: 'school-1',
          createdAt: 1,
        ),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });
  });

  test('l\'accusé range le fil descendu avec la demande', () async {
    await seedMessage('m-1', at: '2026-09-04T08:00:00.000Z');
    when(() => api.decideExpense(any(), any(), any())).thenAnswer(
      (_) async => ExpenseSyncResponseDto(
        expense: canonical(
          thread: const [
            ExpenseMessageDeltaDto(
              id: 'm-serveur',
              body: 'Demande déposée.',
              act: 'DEPOSIT',
              createdAt: '2026-09-03T09:00:00.000Z',
              authorName: 'Moke Junior',
            ),
          ],
        ),
        lwwOutcome: 'APPLIED',
      ),
    );

    await handler().dispatch(entry('m-1'));

    final thread = await messages.threadFor('e-1', schoolId: 'school-1');
    // Le message du serveur entre ; celui du poste est le nôtre, déjà là.
    expect(thread.map((m) => m.id), containsAll(['m-serveur', 'm-1']));
  });

  test('une purge serveur (410) emporte le fil avec la demande', () async {
    await seedMessage('m-1', at: '2026-09-04T08:00:00.000Z');
    when(() => api.decideExpense(any(), any(), any())).thenThrow(http(410));

    final result = await handler().dispatch(entry('m-1'));

    expect(result.outcome, OutboxDispatchOutcome.acked);
    expect(await reader.find('e-1'), isNull);
    // Un fil orphelin qu'aucun écran ne montre, et que le prochain pull de la
    // même dépense mélangerait à son propre historique.
    expect(await messages.threadFor('e-1', schoolId: 'school-1'), isEmpty);
  });
}
