import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_event_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/online/calendar_online_api.dart';
import 'package:school_app_flutter/features/school_calendar/data/repositories/school_calendar_repository_impl.dart';
import 'package:school_app_flutter/features/school_calendar/data/sync/calendar_events_outbox_handler.dart';
import 'package:school_app_flutter/features/school_calendar/data/wire/calendar_wire.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/offline_full_test_db.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final Map<String, dynamic> Function(Map<String, dynamic> body) respond;
  Map<String, dynamic>? sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent = options.data as Map<String, dynamic>;
    return ResponseBody.fromString(
      jsonEncode(respond(sent!)),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

CalendarElement event(String id, {String title = 'Réunion des parents'}) =>
    CalendarElement(
      id: id,
      source: CalendarSource.school,
      nature: CalendarNature.schoolLife,
      title: title,
      startDate: DateTime.utc(2026, 10, 17),
      endDate: DateTime.utc(2026, 10, 17),
      scope: const CycleScope('SEC'),
      toVerify: true,
    );

void main() {
  late Database db;
  late CurrentUserContext user;
  late SchoolCalendarRepositoryImpl repository;
  late DateTime now;

  setUp(() async {
    now = DateTime.utc(2026, 10, 1, 8);
    db = await openFullOfflineDb();
    user = CurrentUserContext()..set('u1', schoolId: 'school-1');
    repository = SchoolCalendarRepositoryImpl(
      db: db,
      online: CalendarOnlineApi(Dio(), const {}),
      currentUser: user,
      ids: const IdGenerator(Uuid()),
      now: () => now,
    );
  });
  tearDown(() => db.close());

  CalendarEventsOutboxHandler handler(
    Map<String, dynamic> Function(Map<String, dynamic>) respond,
    _Adapter adapter,
  ) => CalendarEventsOutboxHandler(
    dio: Dio()..httpClientAdapter = adapter,
    dao: CalendarEventDao(db),
    outbox: OutboxDao(db),
    requiredAuth: const {},
    now: () => now.millisecondsSinceEpoch,
  );

  Future<OutboxDispatchResult> push(
    Map<String, dynamic> Function(Map<String, dynamic>) respond, {
    _Adapter? adapter,
  }) async {
    final a = adapter ?? _Adapter(respond);
    final entry = (await OutboxDao(
      db,
    ).pendingReady(now.millisecondsSinceEpoch)).single;
    return handler(respond, a).dispatch(entry);
  }

  test(
    'un geste pose la ligne en attente et une seule entrée d’envoi',
    () async {
      await repository.saveEvent(calendarId: 'cal', element: event('e1'));
      now = now.add(const Duration(seconds: 1));
      await repository.saveEvent(calendarId: 'cal', element: event('e2'));
      expect(await repository.pendingCount('cal'), 2);
      expect(
        await OutboxDao(db).pendingReady(now.millisecondsSinceEpoch),
        hasLength(1),
      );
    },
  );

  test('l’horloge est monotone même si le poste recule', () async {
    await repository.saveEvent(calendarId: 'cal', element: event('e1'));
    now = now.subtract(const Duration(hours: 1));
    await repository.saveEvent(
      calendarId: 'cal',
      element: event('e1', title: 'Autre'),
    );
    final line = (await CalendarEventDao(db).pending('school-1')).single;
    expect(
      line.clientUpdatedAtMs,
      DateTime.utc(2026, 10, 1, 8).millisecondsSinceEpoch + 1,
    );
  });

  test(
    'APPLIED, SUPERSEDED et REJECTED sont réconciliés ligne par ligne',
    () async {
      for (final id in ['a', 'b', 'c']) {
        await repository.saveEvent(calendarId: 'cal', element: event(id));
      }
      final adapter = _Adapter((body) {
        final lines = (body['events'] as List).cast<Map<String, dynamic>>();
        Map<String, dynamic> echo(Map<String, dynamic> l, {String? title}) => {
          ...l,
          'title': ?title,
          'toVerify': false,
          'serverUpdatedAt': '2026-10-01T08:00:05Z',
        };
        return {
          'results': [
            {
              'id': 'a',
              'outcome': 'APPLIED',
              'event': echo(lines[0]),
              'revision': 4,
            },
            {
              'id': 'b',
              'outcome': 'SUPERSEDED',
              'event': echo(lines[1], title: 'Gagnant'),
            },
            {'id': 'c', 'outcome': 'REJECTED', 'reason': 'CALENDAR_ARCHIVED'},
          ],
        };
      });
      final result = await push((_) => const {}, adapter: adapter);
      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect((adapter.sent!['events'] as List).first['scope'], 'CYCLE:SEC');

      final events = {
        for (final e in await repository.events('cal')) e.element.id: e,
      };
      expect(events['a']!.syncState, RecordSyncState.synced);
      expect(events['b']!.element.title, 'Gagnant');
      expect(events['c']!.syncState, RecordSyncState.failed);
      expect(events['c']!.errorCode, 'CALENDAR_ARCHIVED');
      expect(
        (await repository.takeSuperseded('cal')).map((e) => e.element.id),
        ['b'],
      );
      expect(await repository.takeSuperseded('cal'), isEmpty);
    },
  );

  test(
    'une ligne sans résultat reste en attente et fait rejouer le lot',
    () async {
      await repository.saveEvent(calendarId: 'cal', element: event('a'));
      final result = await push((_) => {'results': []});
      expect(result.outcome, OutboxDispatchOutcome.retry);
      expect(await repository.pendingCount('cal'), 1);
    },
  );

  test('un geste fait pendant l’envoi n’est pas écrasé par l’accusé', () async {
    await repository.saveEvent(calendarId: 'cal', element: event('a'));
    final adapter = _Adapter((body) {
      final line = (body['events'] as List).first as Map<String, dynamic>;
      return {
        'results': [
          {
            'id': 'a',
            'outcome': 'APPLIED',
            'event': {...line, 'serverUpdatedAt': '2026-10-01T08:00:05Z'},
          },
        ],
      };
    });
    final entry = (await OutboxDao(
      db,
    ).pendingReady(now.millisecondsSinceEpoch)).single;
    // La saisie suivante arrive avant la réponse.
    final dao = CalendarEventDao(db);
    final pushing = await dao.pending('school-1');
    now = now.add(const Duration(seconds: 2));
    await repository.saveEvent(
      calendarId: 'cal',
      element: event('a', title: 'Plus récent'),
    );
    await dao.applyServerState(
      id: 'a',
      pushedAt: pushing.single.clientUpdatedAtMs,
      server: CalendarWire.eventFromJson({
        ...CalendarWire.eventToJson(pushing.single),
        'serverUpdatedAt': '2026-10-01T08:00:05Z',
      }),
      superseded: false,
      schoolId: 'school-1',
      nowMs: now.millisecondsSinceEpoch,
    );
    expect(entry.aggregateType, kCalendarEventsBatchAggregateType);
    expect(adapter.sent, isNull);
    final line = (await repository.events('cal')).single;
    expect(line.element.title, 'Plus récent');
    expect(line.isPending, isTrue);
  });

  test(
    'un tirage n’écrase pas une ligne en attente ; une suppression la masque',
    () async {
      await repository.saveEvent(
        calendarId: 'cal',
        element: event('a', title: 'Local'),
      );
      await CalendarEventDao(db).applyPulled(
        [
          CalendarWire.eventFromJson({
            'id': 'a',
            'calendarId': 'cal',
            'nature': 'SCHOOL_LIFE',
            'title': 'Serveur',
            'startDate': '2026-10-17',
            'endDate': '2026-10-17',
            'scope': 'SCHOOL',
            'toVerify': false,
            'clientUpdatedAt': '2026-09-01T00:00:00Z',
            'deleted': false,
          }),
          CalendarWire.eventFromJson({
            'id': 'z',
            'calendarId': 'cal',
            'nature': 'EXAM',
            'title': 'Supprimé',
            'startDate': '2026-10-17',
            'endDate': '2026-10-17',
            'scope': 'SCHOOL',
            'toVerify': false,
            'clientUpdatedAt': '2026-09-01T00:00:00Z',
            'deleted': true,
          }),
        ],
        schoolId: 'school-1',
        nowMs: 1,
      );
      final events = await repository.events('cal');
      expect(events.map((e) => e.element.title), ['Local']);
    },
  );

  test(
    'une suppression refusée n’a pas eu lieu : l’événement revient, marqué',
    () async {
      await repository.saveEvent(calendarId: 'cal', element: event('a'));
      await push(
        (body) => {
          'results': [
            {'id': 'a', 'outcome': 'APPLIED'},
          ],
        },
      );
      now = now.add(const Duration(seconds: 1));
      await repository.deleteEvent(calendarId: 'cal', element: event('a'));
      expect(await repository.events('cal'), isEmpty);
      await push(
        (body) => {
          'results': [
            {
              'id': 'a',
              'outcome': 'REJECTED',
              'reason': 'CALENDAR_ELEMENT_LOCKED',
            },
          ],
        },
      );
      final back = (await repository.events('cal')).single;
      expect(back.syncState, RecordSyncState.failed);
      expect(back.errorCode, 'CALENDAR_ELEMENT_LOCKED');
    },
  );
}
