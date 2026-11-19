import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_draft_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_draft_outbox_handler.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_wire.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/offline/offline_full_test_db.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final Map<String, dynamic> Function(Map<String, dynamic>) respond;
  Map<String, dynamic>? sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    sent = o.data as Map<String, dynamic>;
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

const _slot = TimeSlot(
  id: 's1',
  order: 1,
  startTime: '07:30:00',
  endTime: '08:20:00',
);
const _math = TimetableCourse(
  coursId: 'math',
  classroomId: 'c7a',
  branchId: 'b',
  branchLabel: 'Maths',
  teacherId: 't1',
  teacherLabel: 'Kashala',
);
const _classroom = TimetableClassOption(
  classroomId: 'c7a',
  name: '7e A',
  cycleCode: 'SEC',
  cycleName: 'Sec',
  levelCode: 'L7',
  levelName: '7e',
);

ClassTimetableCell published(Weekday day) => ClassTimetableCell(
  id: ClassTimetableCell.keyOf(
    classroomId: 'c7a',
    status: TimetableCellStatus.published,
    draftId: null,
    day: day,
    slotId: 's1',
  ),
  classroomId: 'c7a',
  classroomLabel: '7e A',
  status: TimetableCellStatus.published,
  day: day,
  slotId: 's1',
  range: const MinuteRange(450, 500),
  coursId: 'math',
  teacherId: 't1',
);

ClassTimetableCell draftCell(String draftId, Weekday day, {String? cours}) =>
    ClassTimetableCell(
      id: ClassTimetableCell.keyOf(
        classroomId: 'c7a',
        status: TimetableCellStatus.draft,
        draftId: draftId,
        day: day,
        slotId: 's1',
      ),
      classroomId: 'c7a',
      classroomLabel: '7e A',
      status: TimetableCellStatus.draft,
      draftId: draftId,
      day: day,
      slotId: 's1',
      range: const MinuteRange(450, 500),
      coursId: cours,
      teacherId: cours == null ? null : 't1',
    );

Map<String, Object?> cellJson(String draftId, Weekday day, {int? clock}) => {
  'id': 'srv-${day.wire}',
  'classroomId': 'c7a',
  'classroomLabel': '7e A',
  'status': 'DRAFT',
  'draftId': draftId,
  'day': day.wire,
  'slotId': 's1',
  'startMinute': 450,
  'endMinute': 500,
  'coursId': 'math',
  'teacherId': 't1',
  'clientUpdatedAt': ?(clock == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          clock,
          isUtc: true,
        ).toIso8601String()),
};

void main() {
  late Database db;
  late TimetableEditor editor;
  late DateTime now;

  setUp(() async {
    db = await openFullOfflineDb();
    now = DateTime.utc(2026, 10, 1, 8);
    editor = TimetableEditor(
      db: db,
      dio: Dio(),
      requiredAuth: const {},
      ids: const IdGenerator(Uuid()),
      schoolId: () => 'school',
      now: () => now,
    );
  });
  tearDown(() => db.close());

  Future<ClassTimetableView> view() async {
    final dao = TimetableDao(db);
    final header = await dao.headerOf('c7a');
    return ClassTimetableView(
      classroom: _classroom,
      grid: null,
      slots: const [_slot],
      header: header,
      published: await dao.cellsOf(
        'c7a',
        status: TimetableCellStatus.published,
      ),
      draft: header?.draftId == null
          ? const []
          : await dao.cellsOf(
              'c7a',
              status: TimetableCellStatus.draft,
              draftId: header!.draftId,
            ),
      programme: const [_math],
      othersKnown: true,
    );
  }

  Future<OutboxDispatchResult> flush(
    Map<String, dynamic> Function(Map<String, dynamic>) respond,
  ) async {
    final handler = TimetableDraftOutboxHandler(
      dio: Dio()..httpClientAdapter = _Adapter(respond),
      dao: TimetableDraftDao(db),
      outbox: OutboxDao(db),
      requiredAuth: const {},
      now: () => now.millisecondsSinceEpoch,
    );
    final entry = (await OutboxDao(
      db,
    ).pendingReady(now.millisecondsSinceEpoch)).first;
    return handler.dispatch(entry);
  }

  Map<String, dynamic> applyAll(Map<String, dynamic> body) => {
    'results': [
      for (final g in (body['gestures'] as List).cast<Map<String, dynamic>>())
        {
          'key': switch (g['kind']) {
            'CELL' => 'CELL:${g['draftId']}:${g['day']}:${g['slotId']}',
            final k => '$k:${g['draftId']}',
          },
          'outcome': 'APPLIED',
        },
    ],
  };

  test(
    'abandon puis recommencement hors ligne : l’abandon part AVANT',
    () async {
      await editor.start(await view());
      final old = (await view()).header!.draftId!;
      expect(await flush(applyAll), isA<OutboxDispatchResult>());
      expect((await view()).header!.pendingGesture, isNull);

      await editor.abandon(await view());
      expect((await view()).hasDraft, isFalse);
      now = now.add(const Duration(seconds: 1));
      await editor.start(await view());
      final fresh = (await view()).header!.draftId!;
      expect(fresh, isNot(old));

      final pending = await TimetableDraftDao(db).pending();
      expect(pending.map((g) => g.key), ['ABANDON:$old', 'START:$fresh']);

      await flush(applyAll);
      final v = await view();
      expect(v.header!.pendingGesture, isNull);
      expect(v.header!.draftId, fresh);
      expect(await TimetableDraftDao(db).pending(), isEmpty);
    },
  );

  test('abandon refusé d’un RESTART (brouillon fini ailleurs) : le '
      'commencer part quand même', () async {
    await editor.start(await view());
    final old = (await view()).header!.draftId!;
    await flush(applyAll);
    await editor.abandon(await view());
    await editor.start(await view());
    final fresh = (await view()).header!.draftId!;
    await flush(
      (body) => {
        'results': [
          {
            'key': 'ABANDON:$old',
            'outcome': 'REJECTED',
            'reason': 'TIMETABLE_DRAFT_ENDED',
          },
          {'key': 'START:$fresh', 'outcome': 'APPLIED'},
        ],
      },
    );
    final v = await view();
    expect(v.header!.draftId, fresh);
    expect(v.header!.pendingGesture, isNull);
    expect(v.header!.errorCode, isNull);
  });

  test(
    'RESTART puis abandon du nouveau : seul l’ancien abandon reste',
    () async {
      await editor.start(await view());
      final old = (await view()).header!.draftId!;
      await flush(applyAll);
      await editor.abandon(await view());
      await editor.start(await view());
      await editor.abandon(await view());
      final pending = await TimetableDraftDao(db).pending();
      expect(pending.map((g) => g.key), ['ABANDON:$old']);
    },
  );

  test('alias : la case rendue sous le brouillon canonique ne se double pas, '
      'et les copies du publié cèdent aux cases de l’autre appareil', () async {
    await db.insert(
      TimetableDao.cells,
      TimetableDao.cellRow(published(Weekday.mon), 1)
        ..['sync_status'] = RecordSyncState.synced.dbValue,
    );
    await editor.start(await view());
    final local = (await view()).header!.draftId!;
    await editor.setCells(await view(), [
      const CellChange(Weekday.tue, _slot, _math),
    ]);
    // Le tirage passe avant l'envoi : l'autre appareil a déjà vidé lundi
    // dans le brouillon ouvert « canon ».
    await TimetableDao(
      db,
    ).applyCells([PulledTimetableRow(draftCell('canon', Weekday.mon), 5)], 5);
    final clock = now.millisecondsSinceEpoch;
    await flush(
      (body) => {
        'results': [
          {
            'key': 'START:$local',
            'outcome': 'APPLIED',
            'timetable': {'draftId': 'canon', 'revision': 7},
          },
          {
            'key': 'CELL:$local:TUE:s1',
            'outcome': 'APPLIED',
            'cell': cellJson('canon', Weekday.tue, clock: clock),
            'timetable': {'draftId': 'canon', 'revision': 8},
          },
        ],
      },
    );
    final v = await view();
    expect(v.header!.draftId, 'canon');
    expect(v.header!.revision, 8, reason: 'la révision du dernier résultat');
    final byDay = <Weekday, List<ClassTimetableCell>>{};
    for (final c in v.draft) {
      byDay.putIfAbsent(c.day, () => []).add(c);
    }
    expect(byDay[Weekday.tue], hasLength(1));
    expect(byDay[Weekday.tue]!.single.coursId, 'math');
    expect(byDay[Weekday.mon], hasLength(1));
    expect(
      byDay[Weekday.mon]!.single.isEmpty,
      isTrue,
      reason: 'la copie périmée du publié n’écrase pas la case canonique',
    );
    final orphans = await db.query(
      TimetableDao.cells,
      where: 'draft_id = ?',
      whereArgs: [local],
    );
    expect(orphans, isEmpty);
  });

  test('une case refusée survit au tirage qui suit', () async {
    await editor.start(await view());
    final draft = (await view()).header!.draftId!;
    await editor.setCells(await view(), [
      const CellChange(Weekday.tue, _slot, _math),
    ]);
    await flush(
      (body) => {
        'results': [
          {'key': 'START:$draft', 'outcome': 'APPLIED'},
          {
            'key': 'CELL:$draft:TUE:s1',
            'outcome': 'REJECTED',
            'reason': 'TIMETABLE_DRAFT_ENDED',
          },
        ],
      },
    );
    await TimetableDao(db).applyCells([
      PulledTimetableRow(draftCell(draft, Weekday.tue), 9, deleted: true),
    ], 9);
    final ended = await TimetableDraftDao(db).endedCells('c7a');
    expect(ended.single.coursId, 'math');
  });

  test(
    'conflits : seul le publié et le brouillon ouvert des classes de '
    'l’année occupent un enseignant ; une case refusée n’occupe personne',
    () async {
      for (final (id, year) in [('c7a', 'y'), ('c7b', 'y'), ('old', 'y0')]) {
        await db.insert('ref_classrooms', {
          'id': id,
          'academic_year_id': year,
          'name': id,
        });
      }
      for (final (id, draft) in [('c7b', 'open'), ('old', null)]) {
        await db.insert(TimetableDao.headers, {
          'id': 'h-$id',
          'classroom_id': id,
          'academic_year_id': 'y',
          'revision': 1,
          'draft_id': draft,
          'synced_at': 1,
        });
      }
      Future<void> put(
        String classroom,
        TimetableCellStatus status,
        String? draftId,
        Weekday day, {
        String sync = 'SYNCED',
      }) => db.insert(TimetableDao.cells, {
        ...TimetableDao.cellRow(
          ClassTimetableCell(
            id: ClassTimetableCell.keyOf(
              classroomId: classroom,
              status: status,
              draftId: draftId,
              day: day,
              slotId: 's1',
            ),
            classroomId: classroom,
            classroomLabel: classroom,
            status: status,
            draftId: draftId,
            day: day,
            slotId: 's1',
            range: const MinuteRange(450, 500),
            coursId: 'x',
            teacherId: 't1',
          ),
          1,
        ),
        'sync_status': sync,
      });
      await put('c7b', TimetableCellStatus.published, null, Weekday.mon);
      await put('c7b', TimetableCellStatus.draft, 'open', Weekday.tue);
      await put('c7b', TimetableCellStatus.draft, 'dead', Weekday.wed);
      await put(
        'c7b',
        TimetableCellStatus.draft,
        'open',
        Weekday.thu,
        sync: RecordSyncState.failed.dbValue,
      );
      await put('old', TimetableCellStatus.published, null, Weekday.fri);
      final bookings = await TimetableDao(db).bookingsOutside('c7a');
      expect(bookings.map((b) => b.day).toSet(), {Weekday.mon, Weekday.tue});
    },
  );
}
