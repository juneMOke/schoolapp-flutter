import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_outbox.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_sync_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_write_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_entry_dto.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_outbox_handler.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_push.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_sync_api.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_sync_dao.dart'
    show ChapitreServerState;
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

class _MockApi extends Mock implements JournalSyncApi {}

DioException _dio(int status, {String? detailCode}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: detailCode == null ? null : {'detailCode': detailCode},
  ),
);

void main() {
  late Database db;
  late _MockApi api;
  late List<String> evicted;
  late ChapitreServerState chapitreState;
  late bool chapitreRejected;
  late JournalOutboxHandler handler;
  final user = CurrentUserContext()..set('u-1', schoolId: 's-1');
  const extras = <String, dynamic>{};
  const sent = '2026-10-12T08:00:00.000Z';

  final entry = JournalEntry(
    id: 'e-1',
    coursId: 'c-1',
    date: DateTime(2026, 10, 12),
    timeSlotId: 's-1',
    chapitreId: 'ch-1',
    fields: const JournalFields(objectif: 'Calculer', contenu: 'Aires'),
    clientUpdatedAt: DateTime.parse(sent),
  );
  final outboxEntry = OutboxEntry(
    id: JournalOutbox.entry('e-1'),
    aggregateType: JournalOutbox.type,
    aggregateId: 'e-1',
    operation: OutboxOperation.upsert,
    payload: jsonEncode({
      ...JournalEntryPayload.of(entry).toJson(),
      'authorId': 'u-1',
    }),
    schoolId: 's-1',
    createdAt: 1,
  );

  JournalEntryAck ackOf({
    String? chapitreId = 'ch-1',
    bool superseded = false,
  }) => JournalEntryAck(
    entry: JournalEntryDto(
      id: 'e-1',
      coursId: 'c-1',
      date: '2026-10-12',
      timeSlotId: 's-1',
      chapitreId: chapitreId,
      fields: const JournalFields(objectif: 'Calculer', contenu: 'Aires'),
      clientUpdatedAt: sent,
      serverUpdatedAt: '2026-10-12T09:00:00.000Z',
    ),
    superseded: superseded,
  );

  Future<JournalEntry> stored() async =>
      (await JournalDao(db).entriesOfCours({'c-1'})).single;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    evicted = [];
    chapitreState = ChapitreServerState.known;
    chapitreRejected = false;
    await JournalWriteDao(db).save(entry, schoolId: 's-1', nowMs: 1);
    handler = JournalOutboxHandler(
      api: api,
      dao: JournalSyncDao(db),
      chapitreState: (_) async => chapitreState,
      chapitreRejected: (_) async => chapitreRejected,
      evictCours: (coursId) async => evicted.add(coursId),
      currentUser: user,
      extras: extras,
      now: () => 9,
    );
  });
  tearDown(() => db.close());

  test(
    'accusée : l\'entrée part enveloppée, la ligne est synchronisée',
    () async {
      when(() => api.saveEntry(extras, any())).thenAnswer((_) async => ackOf());

      final result = await handler.dispatch(outboxEntry);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final body =
          verify(() => api.saveEntry(extras, captureAny())).captured.single
              as Map<String, dynamic>;
      expect(body['authorId'], 'u-1');
      expect((body['entry'] as Map)['date'], '2026-10-12');
      expect((await stored()).syncState, RecordSyncState.synced);
    },
  );

  test('chapitre pas encore accusé : l\'entrée attend, sans réseau', () async {
    chapitreState = ChapitreServerState.unknown;

    final result = await handler.dispatch(outboxEntry);

    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.saveEntry(any(), any()));
  });

  test('chapitre refusé : la séance est à corriger, sans réseau', () async {
    chapitreState = ChapitreServerState.unknown;
    chapitreRejected = true;

    final result = await handler.dispatch(outboxEntry);

    expect(result.outcome, OutboxDispatchOutcome.failed);
    expect((await stored()).rejectionCode, kJournalChapitreRejectedCode);
    verifyNever(() => api.saveEntry(any(), any()));
  });

  test(
    'chapitre absent de la tablette : l\'entrée part telle quelle',
    () async {
      chapitreState = ChapitreServerState.gone;
      when(() => api.saveEntry(extras, any())).thenAnswer((_) async => ackOf());

      await handler.dispatch(outboxEntry);

      final body =
          verify(() => api.saveEntry(extras, captureAny())).captured.single
              as Map<String, dynamic>;
      expect((body['entry'] as Map)['chapitreId'], 'ch-1');
    },
  );

  test(
    'chapitre absent que le serveur n\'a jamais vu : renvoi détaché',
    () async {
      chapitreState = ChapitreServerState.gone;
      final bodies = <Map<String, dynamic>>[];
      when(() => api.saveEntry(extras, any())).thenAnswer((invocation) async {
        final body = invocation.positionalArguments[1] as Map<String, dynamic>;
        bodies.add(body);
        if ((body['entry'] as Map)['chapitreId'] != null) {
          throw _dio(409, detailCode: 'CHAPITRE_NOT_YET_SYNCED');
        }
        return ackOf(chapitreId: null);
      });

      final result = await handler.dispatch(outboxEntry);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect(bodies, hasLength(2));
      expect((await stored()).chapitreId, isNull);
    },
  );

  test('404 : le cours n\'existe plus, la séance quitte la tablette', () async {
    when(() => api.saveEntry(extras, any())).thenThrow(_dio(404));

    final result = await handler.dispatch(outboxEntry);

    expect(result.outcome, OutboxDispatchOutcome.acked);
    expect(await JournalDao(db).entriesOfCours({'c-1'}), isEmpty);
  });

  test('409 CHAPITRE_NOT_YET_SYNCED : une attente, pas un refus', () async {
    when(
      () => api.saveEntry(extras, any()),
    ).thenThrow(_dio(409, detailCode: 'CHAPITRE_NOT_YET_SYNCED'));

    final result = await handler.dispatch(outboxEntry);

    expect(result.outcome, OutboxDispatchOutcome.blocked);
    expect((await stored()).syncState, RecordSyncState.pending);
  });

  test('403 COURS_NOT_OWNED : le cours est évincé', () async {
    when(
      () => api.saveEntry(extras, any()),
    ).thenThrow(_dio(403, detailCode: 'COURS_NOT_OWNED'));

    final result = await handler.dispatch(outboxEntry);

    expect(result.outcome, OutboxDispatchOutcome.acked);
    expect(evicted, ['c-1']);
  });

  test('422 : la séance est à corriger', () async {
    when(
      () => api.saveEntry(extras, any()),
    ).thenThrow(_dio(422, detailCode: 'JOURNAL_ENTRY_INCOMPLETE'));

    final result = await handler.dispatch(outboxEntry);

    expect(result.outcome, OutboxDispatchOutcome.failed);
    final row = await stored();
    expect(row.isRejected, isTrue);
    expect(row.rejectionCode, 'JOURNAL_ENTRY_INCOMPLETE');
  });

  test('réseau ou 5xx : on rejoue', () async {
    when(() => api.saveEntry(extras, any())).thenThrow(_dio(503));

    expect(
      (await handler.dispatch(outboxEntry)).outcome,
      OutboxDispatchOutcome.retry,
    );
  });
}
