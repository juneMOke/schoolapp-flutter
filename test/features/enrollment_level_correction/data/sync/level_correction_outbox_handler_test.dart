import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/level_correction_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_api.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../level_correction_fixtures.dart';

class _MockApi extends Mock implements LevelCorrectionApi {}

DioException _refused(int status, String code) => DioException(
  requestOptions: RequestOptions(),
  response: Response(
    requestOptions: RequestOptions(),
    statusCode: status,
    data: {'detailCode': code, 'message': code},
  ),
);

void main() {
  late Database db;
  late _MockApi api;
  late LevelCorrectionWriteDao writer;
  late LevelCorrectionReadDao reader;
  late OutboxDependencyState dependency;
  late int refreshes;
  late LevelCorrectionChangeBus bus;
  late List<Set<String>> emitted;
  late LevelCorrectionOutboxHandler handler;

  setUpAll(() => registerFallbackValue(correctionGesture('fallback')));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    writer = LevelCorrectionWriteDao(db);
    reader = LevelCorrectionReadDao(db);
    dependency = OutboxDependencyState.ready;
    refreshes = 0;
    bus = LevelCorrectionChangeBus();
    emitted = [];
    bus.stream.listen(emitted.add);
    handler = LevelCorrectionOutboxHandler(
      api: api,
      sync: LevelCorrectionSyncDao(db),
      outbox: OutboxDao(db),
      dependency: (_, _) async => dependency,
      bus: bus,
      currentUser: CurrentUserContext()..set(kAuthor, schoolId: kSchool),
      extras: const {},
      refresh: () async => refreshes++,
      now: () => 99,
    );
  });
  tearDown(() => db.close());

  Future<void> record(String id) =>
      writer.record(correctionGesture(id), schoolId: kSchool, nowMs: 1);

  Future<OutboxEntry> entryOf(String id) async =>
      (await OutboxDao(db).byId(LevelCorrectionWriteDao.entryId(id)))!;

  Future<OutboxDispatchResult> dispatch(String id) async =>
      handler.dispatch(await entryOf(id));

  Future<LevelCorrection?> latest() => reader.latestFor(kEnrollment);

  test('accusé : la correction est appliquée, la descente lancée, puis '
      'annoncée une seconde fois une fois faite', () async {
    await record('g-1');
    when(() => api.push(any(), any())).thenAnswer((_) async {});

    final result = await dispatch('g-1');
    await pumpEventQueue();

    expect(result.outcome, OutboxDispatchOutcome.acked);
    expect((await latest())?.status, LevelCorrectionStatus.applied);
    expect(refreshes, 1);
    // Le premier signal à l'accusé, le second après la descente : c'est elle
    // qui lève la garde du guichet.
    expect(emitted, [
      {kEnrollment},
      {kEnrollment},
    ]);
    verify(() => api.push(any(), correctionGesture('g-1'))).called(1);
  });

  test('une descente qui échoue ne défait pas l\'accusé', () async {
    await record('g-1');
    when(() => api.push(any(), any())).thenAnswer((_) async {});
    handler = LevelCorrectionOutboxHandler(
      api: api,
      sync: LevelCorrectionSyncDao(db),
      outbox: OutboxDao(db),
      dependency: (_, _) async => dependency,
      bus: bus,
      currentUser: CurrentUserContext()..set(kAuthor, schoolId: kSchool),
      extras: const {},
      refresh: () async => throw StateError('hors ligne'),
      now: () => 99,
    );

    final result = await dispatch('g-1');
    await pumpEventQueue();

    expect(result.outcome, OutboxDispatchOutcome.acked);
    expect((await latest())?.status, LevelCorrectionStatus.applied);
  });

  test('inscription pas encore accusée localement : le geste attend, sans '
      'partir', () async {
    await record('g-1');
    dependency = OutboxDependencyState.waiting;

    expect((await dispatch('g-1')).outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.push(any(), any()));
  });

  test(
    '409 ENROLLMENT_NOT_YET_SYNCED : attente, la ligne reste en file',
    () async {
      await record('g-1');
      when(
        () => api.push(any(), any()),
      ).thenThrow(_refused(409, 'ENROLLMENT_NOT_YET_SYNCED'));

      expect((await dispatch('g-1')).outcome, OutboxDispatchOutcome.blocked);
      expect((await latest())?.status, LevelCorrectionStatus.pending);
    },
  );

  test('422 : refus terminal, le code reste sur la ligne', () async {
    await record('g-1');
    when(
      () => api.push(any(), any()),
    ).thenThrow(_refused(422, 'LEVEL_CORRECTION_HAS_PAYMENTS'));

    final result = await dispatch('g-1');

    expect(result.outcome, OutboxDispatchOutcome.failed);
    final row = await latest();
    expect(row?.status, LevelCorrectionStatus.refused);
    expect(row?.refusalCode, 'LEVEL_CORRECTION_HAS_PAYMENTS');
    expect(refreshes, 0);
  });

  test('5xx : rejouable, la ligne reste en attente', () async {
    await record('g-1');
    when(() => api.push(any(), any())).thenThrow(_refused(503, 'DOWN'));

    expect((await dispatch('g-1')).outcome, OutboxDispatchOutcome.retry);
    expect((await latest())?.status, LevelCorrectionStatus.pending);
  });

  test('410 : l\'inscription a disparu, le geste aussi', () async {
    await record('g-1');
    when(() => api.push(any(), any())).thenThrow(_refused(410, 'GONE'));

    expect((await dispatch('g-1')).outcome, OutboxDispatchOutcome.acked);
    expect(await latest(), isNull);
  });

  test('un geste déjà jugé ne repart pas', () async {
    await record('g-1');
    await LevelCorrectionSyncDao(db).markApplied('g-1', nowMs: 5);

    expect((await dispatch('g-1')).outcome, OutboxDispatchOutcome.acked);
    verifyNever(() => api.push(any(), any()));
  });

  test("un geste d'un autre auteur attend son auteur", () async {
    await writer.record(
      correctionGesture('g-1', authorId: 'u-autre'),
      schoolId: kSchool,
      nowMs: 1,
    );

    final result = await dispatch('g-1');

    expect(result.outcome, isNot(OutboxDispatchOutcome.acked));
    verifyNever(() => api.push(any(), any()));
  });

  test("un geste d'une autre école n'est pas envoyé", () async {
    await writer.record(
      correctionGesture('g-1'),
      schoolId: 'school-2',
      nowMs: 1,
    );

    final result = await dispatch('g-1');

    expect(result.outcome, isNot(OutboxDispatchOutcome.acked));
    verifyNever(() => api.push(any(), any()));
  });

  test('payload illisible : échec terminal', () async {
    final result = await handler.dispatch(
      const OutboxEntry(
        id: 'ENROLLMENT_LEVEL_CORRECTION:x',
        aggregateType: 'ENROLLMENT_LEVEL_CORRECTION',
        aggregateId: kEnrollment,
        operation: OutboxOperation.create,
        payload: '{"id": "x"}',
        schoolId: kSchool,
        createdAt: 1,
      ),
    );
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });
}
