import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_pull_api.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/schedule_pull_models.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/offline/ref_pull_outcome.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockSchedulePullApi extends Mock implements SchedulePullApi {}

void main() {
  late Database db;
  late MockSchedulePullApi api;
  late SyncMetaDao syncMeta;
  late ScheduleRefLocalDataSource local;
  late SchedulePullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockSchedulePullApi();
    syncMeta = SyncMetaDao(db);
    local = ScheduleRefLocalDataSource(db);
    repo = SchedulePullRepositoryImpl(
      api: api,
      localDataSource: local,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => 10000,
    );
  });

  tearDown(() async => db.close());

  RefPullOutcome right(Either<Failure, RefPullOutcome> e) =>
      e.fold((f) => fail('Attendu Right, reçu Left($f)'), (o) => o);

  HttpResponse<T> httpOk<T>(T body) => HttpResponse(
    body,
    Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
  );

  DioException status(int code) => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: code,
    ),
  );

  TimeSlotPageDto page(
    List<TimeSlotDeltaDto> items, {
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
  }) => TimeSlotPageDto(
    items: items,
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-07-19T10:00:00Z',
    ),
  );

  TimeSlotDeltaDto slot(String id, {int order = 1}) => TimeSlotDeltaDto(
    id: id,
    slotOrder: order,
    startTime: '08:00',
    endTime: '08:50',
    serverUpdatedAt: '2026-07-19T09:00:00Z',
  );

  group('syncTimeSlots (keyset)', () {
    test(
      'bootstrap : page unique appliquée, watermark mémorisé, bootstrap OK',
      () async {
        when(() => api.pullTimeSlots(auth, null, 100)).thenAnswer(
          (_) async =>
              httpOk(page([slot('t1'), slot('t2')], nextWatermark: 'wm-1')),
        );

        final outcome = right(await repo.syncTimeSlots());

        expect(outcome.upserted, 2);
        expect(outcome.notModified, isFalse);
        expect(outcome.bootstrapComplete, isTrue);
        // Horloge SERVEUR (page.serverTime), pas l'horloge locale injectée.
        expect(
          outcome.serverTimeMs,
          DateTime.parse('2026-07-19T10:00:00Z').millisecondsSinceEpoch,
        );
        expect(await syncMeta.getCursor(kScheduleTimeSlotsResource), 'wm-1');
        expect((await local.getTimeSlots()).length, 2);
      },
    );

    test(
      'multi-pages : curseur mémorisé à chaque page, watermark en fin',
      () async {
        when(() => api.pullTimeSlots(auth, null, 100)).thenAnswer(
          (_) async =>
              httpOk(page([slot('t1')], nextCursor: 'c1', hasMore: true)),
        );
        when(() => api.pullTimeSlots(auth, 'c1', 100)).thenAnswer(
          (_) async => httpOk(page([slot('t2')], nextWatermark: 'wm-2')),
        );

        final outcome = right(await repo.syncTimeSlots());

        expect(outcome.upserted, 2);
        expect(await syncMeta.getCursor(kScheduleTimeSlotsResource), 'wm-2');
        verify(() => api.pullTimeSlots(auth, null, 100)).called(1);
        verify(() => api.pullTimeSlots(auth, 'c1', 100)).called(1);
      },
    );

    test('304 → notModified, curseur conservé', () async {
      await syncMeta.setCursor(
        kScheduleTimeSlotsResource,
        cursor: 'wm-prev',
        syncedAt: 1,
      );
      when(
        () => api.pullTimeSlots(auth, 'wm-prev', 100),
      ).thenThrow(status(304));

      final outcome = right(await repo.syncTimeSlots());

      expect(outcome.notModified, isTrue);
      expect(await syncMeta.getCursor(kScheduleTimeSlotsResource), 'wm-prev');
      expect(outcome.serverTimeMs, isNull);
    });

    test('400 → curseur illisible : rebootstrap depuis null', () async {
      await syncMeta.setCursor(
        kScheduleTimeSlotsResource,
        cursor: 'forged',
        syncedAt: 1,
      );
      when(() => api.pullTimeSlots(auth, 'forged', 100)).thenThrow(status(400));
      when(() => api.pullTimeSlots(auth, null, 100)).thenAnswer(
        (_) async => httpOk(page([slot('t1')], nextWatermark: 'wm-fresh')),
      );

      final outcome = right(await repo.syncTimeSlots());

      expect(outcome.upserted, 1);
      expect(await syncMeta.getCursor(kScheduleTimeSlotsResource), 'wm-fresh');
      verify(() => api.pullTimeSlots(auth, null, 100)).called(1);
    });

    test('404 → PAS de traitement notModified (pas de notion d\'enseignant sur '
        'les créneaux, école entière) : erreur propagée en Left', () async {
      when(() => api.pullTimeSlots(auth, null, 100)).thenThrow(status(404));

      final result = await repo.syncTimeSlots();

      expect(result.isLeft(), isTrue);
    });
  });

  group('syncSessions (keyset, curseur indépendant)', () {
    RecurringSessionPageDto sessionsPage(
      List<RecurringSessionDeltaDto> items, {
      String? nextWatermark,
      bool hasMore = false,
    }) => RecurringSessionPageDto(
      items: items,
      page: KeysetPageEnvelope(
        nextWatermark: nextWatermark,
        hasMore: hasMore,
        serverTime: '2026-07-19T10:00:00Z',
      ),
    );

    RecurringSessionDeltaDto session(String id) => RecurringSessionDeltaDto(
      id: id,
      academicYearId: 'ay-1',
      coursId: 'cours-1',
      timeSlotId: 't1',
      dayOfWeek: 'MON',
      teacherId: 'teach-1',
      classroomId: 'class-1',
      teacherLabel: 'M. Diop',
      classroomLabel: '3e A',
      subjectLabel: 'Maths',
      serverUpdatedAt: '2026-07-19T09:00:00Z',
    );

    test('bootstrap sessions : curseur sur sa propre clé sync_meta', () async {
      when(() => api.pullSessions(auth, null, 100, null)).thenAnswer(
        (_) async => httpOk(sessionsPage([session('s1')], nextWatermark: 'sw')),
      );

      final outcome = right(await repo.syncSessions());

      expect(outcome.upserted, 1);
      expect(await syncMeta.getCursor(kScheduleSessionsResource), 'sw');
      // La clé time-slots n'est pas touchée (curseurs indépendants).
      expect(await syncMeta.getCursor(kScheduleTimeSlotsResource), isNull);
      expect(
        (await local.getSessionsForYear('ay-1')).single.coursId,
        'cours-1',
      );
    });

    test('404 (compte non lié à un enseignant, DF-K) → notModified, jamais '
        'une erreur', () async {
      when(
        () => api.pullSessions(auth, null, 100, null),
      ).thenThrow(status(404));

      final outcome = right(await repo.syncSessions());

      expect(outcome.notModified, isTrue);
      verify(() => api.pullSessions(auth, null, 100, null)).called(1);
    });
  });
}
