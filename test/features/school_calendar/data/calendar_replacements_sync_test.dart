import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_event_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_reference_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/online/calendar_online_api.dart';
import 'package:school_app_flutter/features/school_calendar/data/repositories/school_calendar_repository_impl.dart';
import 'package:school_app_flutter/features/school_calendar/data/sync/calendar_events_outbox_handler.dart';
import 'package:school_app_flutter/features/school_calendar/data/sync/calendar_pullers.dart';
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

CalendarElement _replacement(
  String id, {
  CalendarNature nature = CalendarNature.schoolLife,
  String replaces = 'proclamation-p1',
  String title = 'Proclamation du 1er trimestre',
}) => CalendarElement(
  id: id,
  source: CalendarSource.school,
  nature: nature,
  title: title,
  startDate: DateTime.utc(2026, 11, 17),
  endDate: DateTime.utc(2026, 11, 17),
  scope: const RhythmScope(PeriodRhythm.trimester),
  replaces: replaces,
);

Map<String, dynamic> _applied(Map<String, dynamic> body) => {
  'results': [
    for (final line in body['events'] as List)
      {'id': (line as Map)['id'], 'outcome': 'APPLIED'},
  ],
};

void main() {
  late Database db;
  late SchoolCalendarRepositoryImpl repository;
  late DateTime now;

  setUp(() async {
    now = DateTime.utc(2026, 10, 1, 8);
    db = await openFullOfflineDb();
    repository = SchoolCalendarRepositoryImpl(
      db: db,
      online: CalendarOnlineApi(Dio(), const {}),
      currentUser: CurrentUserContext()..set('u1', schoolId: 'school-1'),
      ids: const IdGenerator(Uuid()),
      now: () => now,
    );
  });
  tearDown(() => db.close());

  Future<_Adapter> push({void Function()? onPeriodsMoved}) async {
    final adapter = _Adapter(_applied);
    final entry = (await OutboxDao(
      db,
    ).pendingReady(now.millisecondsSinceEpoch)).single;
    await CalendarEventsOutboxHandler(
      dio: Dio()..httpClientAdapter = adapter,
      dao: CalendarEventDao(db),
      outbox: OutboxDao(db),
      requiredAuth: const {},
      now: () => now.millisecondsSinceEpoch,
      onPeriodsMoved: onPeriodsMoved,
    ).dispatch(entry);
    return adapter;
  }

  test('un remplacement part avec replacesItemId, nature et portée', () async {
    await repository.saveEvent(calendarId: 'cal', element: _replacement('r1'));
    final line = ((await push()).sent!['events'] as List).single as Map;
    expect(line['replacesItemId'], 'proclamation-p1');
    expect(line['scope'], 'RHYTHM:TRIMESTER');
    expect(line['nature'], 'SCHOOL_LIFE');
  });

  test(
    'modifier un remplacement garde sa cible, même si l’élément la perd',
    () async {
      await repository.saveEvent(
        calendarId: 'cal',
        element: _replacement('r1'),
      );
      now = now.add(const Duration(seconds: 1));
      final edited = CalendarElement(
        id: 'r1',
        source: CalendarSource.school,
        nature: CalendarNature.schoolLife,
        title: 'Proclamation décalée',
        startDate: DateTime.utc(2026, 11, 18),
        endDate: DateTime.utc(2026, 11, 18),
        scope: const RhythmScope(PeriodRhythm.trimester),
      );
      await repository.saveEvent(calendarId: 'cal', element: edited);
      final stored = (await CalendarEventDao(db).eventsOf('cal')).single;
      expect(stored.element.replaces, 'proclamation-p1');
      expect(stored.element.title, 'Proclamation décalée');
    },
  );

  test(
    'une période remplacée acceptée relit les périodes, une seule fois',
    () async {
      await repository.saveEvent(
        calendarId: 'cal',
        element: _replacement(
          'p',
          nature: CalendarNature.period,
          replaces: 'p2-semestre',
        ),
      );
      await repository.saveEvent(calendarId: 'cal', element: _replacement('v'));
      var pulls = 0;
      await push(onPeriodsMoved: () => pulls++);
      expect(pulls, 1);
    },
  );

  test('un remplacement hors période ne relit rien', () async {
    await repository.saveEvent(calendarId: 'cal', element: _replacement('v'));
    var pulls = 0;
    await push(onPeriodsMoved: () => pulls++);
    expect(pulls, 0);
  });

  test('un remplacement descendu garde sa cible', () async {
    await CalendarEventDao(db).applyPulled(
      [
        CalendarWire.eventFromJson({
          'id': 'r1',
          'calendarId': 'cal',
          'nature': 'SCHOOL_LIFE',
          'title': 'Proclamation',
          'startDate': '2026-11-17',
          'endDate': '2026-11-17',
          'scope': 'RHYTHM:TRIMESTER',
          'replacesItemId': 'proclamation-p1',
          'clientUpdatedAt': '2026-10-01T08:00:00Z',
          'serverUpdatedAt': '2026-10-01T08:00:01Z',
        }),
      ],
      schoolId: 'school-1',
      nowMs: now.millisecondsSinceEpoch,
    );
    final stored = (await CalendarEventDao(db).eventsOf('cal')).single;
    expect(stored.element.replaces, 'proclamation-p1');
  });

  test('le cadre descend avec « remplaçable » et son document', () async {
    final dao = CalendarReferenceDao(db);
    await dao.applyFrameworks(
      [
        CalendarWire.frameworkFromJson({
          'id': 'f-2627',
          'yearLabel': '2026-2027',
          'version': 2,
          'startDate': '2026-09-01',
          'endDate': '2027-07-02',
          'document': {
            'fileName': 'calendrier-scolaire-2026-2027.pdf',
            'sizeBytes': 120400,
            'uploadedAt': '2026-08-20T10:00:00Z',
          },
          'items': [
            {
              'id': 'proclamation-p1',
              'nature': 'SCHOOL_LIFE',
              'title': 'Proclamation',
              'startDate': '2026-11-14',
              'endDate': '2026-11-14',
              'scope': 'RHYTHM:TRIMESTER',
              'replaceable': true,
            },
            {
              'id': 'exetat',
              'nature': 'EXAM',
              'title': 'Exetat',
              'startDate': '2027-06-14',
              'endDate': '2027-06-18',
              'scope': 'CATALOG_LEVEL:HG-LP-4,HS-4',
              'replaceable': false,
            },
          ],
        }),
      ],
      schoolId: 'school-1',
      nowMs: now.millisecondsSinceEpoch,
    );
    final framework = (await dao.frameworks('school-1')).single;
    expect(framework.document?.fileName, 'calendrier-scolaire-2026-2027.pdf');
    expect(framework.document?.sizeBytes, 120400);
    final byId = {for (final i in framework.items) i.id: i};
    expect(byId['proclamation-p1']!.replaceable, isTrue);
    expect(byId['exetat']!.replaceable, isFalse);
    expect(byId['exetat']!.scope, const CatalogLevelScope(['HG-LP-4', 'HS-4']));
  });

  test(
    'v86 : les curseurs du cadre et des événements repartent de zéro',
    () async {
      for (final resource in [
        'calendar_framework@school-1',
        'calendar_events@school-1',
        'calendar_calendars@school-1',
        'calendarXevents@school-1',
      ]) {
        await db.insert('sync_meta', {'resource': resource, 'cursor': 'c'});
      }
      await migrateTenantDatabase(db, 85, newVersion: 86);
      final left = [
        for (final r in await db.query('sync_meta', orderBy: 'resource'))
          r['resource'],
      ];
      expect(left, ['calendarXevents@school-1', 'calendar_calendars@school-1']);
    },
  );

  test(
    'une modification refusée d’un remplacement accepté masque toujours',
    () async {
      await CalendarEventDao(db).applyPulled(
        [
          CalendarWire.eventFromJson({
            'id': 'r1',
            'calendarId': 'cal',
            'nature': 'SCHOOL_LIFE',
            'title': 'Proclamation',
            'startDate': '2026-11-17',
            'endDate': '2026-11-17',
            'scope': 'RHYTHM:TRIMESTER',
            'replacesItemId': 'proclamation-p1',
            'clientUpdatedAt': '2026-10-01T08:00:00Z',
            'serverUpdatedAt': '2026-10-01T08:00:01Z',
          }),
        ],
        schoolId: 'school-1',
        nowMs: now.millisecondsSinceEpoch,
      );
      now = now.add(const Duration(minutes: 1));
      await repository.saveEvent(
        calendarId: 'cal',
        element: _replacement('r1', title: 'Décalée'),
      );
      await repository.saveEvent(
        calendarId: 'cal',
        element: _replacement('r2'),
      );
      final entry = (await OutboxDao(
        db,
      ).pendingReady(now.millisecondsSinceEpoch)).single;
      await CalendarEventsOutboxHandler(
        dio: Dio()
          ..httpClientAdapter = _Adapter(
            (body) => {
              'results': [
                for (final line in body['events'] as List)
                  {
                    'id': (line as Map)['id'],
                    'outcome': 'REJECTED',
                    'reason': 'CALENDAR_ELEMENT_LOCKED',
                  },
              ],
            },
          ),
        dao: CalendarEventDao(db),
        outbox: OutboxDao(db),
        requiredAuth: const {},
        now: () => now.millisecondsSinceEpoch,
      ).dispatch(entry);
      final byId = {
        for (final r in await CalendarEventDao(db).eventsOf('cal'))
          r.element.id: r,
      };
      expect(byId['r1']!.isRejected, isTrue);
      expect(byId['r1']!.isRejectedCreation, isFalse);
      expect(byId['r2']!.isRejectedCreation, isTrue);
    },
  );

  test('un remplacement de période descendu relit les périodes', () async {
    var pulls = 0;
    final feed = CalendarFeed.events(
      CalendarEventDao(db),
      onPeriodsMoved: () => pulls++,
    );
    Object row(String id, String nature) => CalendarWire.eventFromJson({
      'id': id,
      'calendarId': 'cal',
      'nature': nature,
      'title': id,
      'startDate': '2026-11-17',
      'endDate': '2026-11-17',
      'scope': 'RHYTHM:SEMESTER',
      'replacesItemId': 'national-$id',
      'clientUpdatedAt': '2026-10-01T08:00:00Z',
      'serverUpdatedAt': '2026-10-01T08:00:01Z',
    });
    await feed.apply([row('a', 'SCHOOL_LIFE')], 'school-1', 1);
    expect(pulls, 0);
    await feed.apply([row('b', 'PERIOD')], 'school-1', 1);
    expect(pulls, 1);
  });

  test(
    'une période et ses sous-périodes se rétablissent dans le même lot',
    () async {
      await repository.saveEvent(
        calendarId: 'cal',
        element: _replacement(
          't1',
          nature: CalendarNature.period,
          replaces: 'T1',
        ),
      );
      await repository.saveEvent(
        calendarId: 'cal',
        element: _replacement(
          'p2',
          nature: CalendarNature.period,
          replaces: 'P2',
        ),
      );
      await push();
      now = now.add(const Duration(minutes: 1));
      await repository.deleteEvents(
        calendarId: 'cal',
        elements: [
          _replacement('t1', nature: CalendarNature.period, replaces: 'T1'),
          _replacement('p2', nature: CalendarNature.period, replaces: 'P2'),
        ],
      );
      final sent = ((await push()).sent!['events'] as List).cast<Map>();
      expect([for (final l in sent) l['id']], ['p2', 't1']..sort());
      expect(sent.every((l) => l['deleted'] == true), isTrue);
      expect(sent.every((l) => l['replacesItemId'] != null), isTrue);
    },
  );
}
