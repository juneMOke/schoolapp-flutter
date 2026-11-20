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

  test(
    'commencer recopie la version publiée et met le geste en file',
    () async {
      await TimetableDao(
        db,
      ).applyCells([PulledTimetableRow(published(Weekday.mon), 1)], 1);
      await editor.start(await view());
      final v = await view();
      expect(v.header!.pendingGesture, 'START');
      expect(v.draft.single.coursId, 'math');
      expect(v.draft.single.syncState, RecordSyncState.synced);
      expect(
        (await TimetableDraftDao(db).pending()).single,
        isA<StartGesture>(),
      );
      expect(
        await OutboxDao(db).pendingReady(now.millisecondsSinceEpoch),
        hasLength(1),
      );
    },
  );

  test(
    'gestes en file : commencer, cases dans l’ordre, puis abandonner',
    () async {
      await editor.start(await view());
      await editor.setCells(await view(), [
        const CellChange(Weekday.tue, _slot, _math),
      ]);
      now = now.add(const Duration(seconds: 1));
      await editor.setCells(await view(), [
        const CellChange(Weekday.wed, _slot, _math),
      ]);
      final pending = await TimetableDraftDao(db).pending();
      expect(pending.map((g) => g.runtimeType), [
        StartGesture,
        CellGesture,
        CellGesture,
      ]);
      // Un brouillon jamais envoyé s'abandonne sur l'appareil seul.
      await editor.abandon(await view());
      final after = await TimetableDraftDao(db).pending();
      expect(after, isEmpty);
      expect((await view()).hasDraft, isFalse);
    },
  );

  test(
    'le lot réconcilie : alias de brouillon, case écrasée, case refusée',
    () async {
      await editor.start(await view());
      final localDraft = (await view()).header!.draftId!;
      await editor.setCells(await view(), [
        const CellChange(Weekday.tue, _slot, _math),
      ]);
      await editor.setCells(await view(), [
        const CellChange(Weekday.wed, _slot, _math),
      ]);
      final adapter = _Adapter((body) {
        final gestures = (body['gestures'] as List)
            .cast<Map<String, dynamic>>();
        return {
          'results': [
            for (final g in gestures)
              switch (g['kind']) {
                'START' => {
                  'key': 'START:$localDraft',
                  'outcome': 'APPLIED',
                  'timetable': {'draftId': 'canon'},
                },
                _ when g['day'] == 'TUE' => {
                  'key': 'CELL:$localDraft:TUE:s1',
                  'outcome': 'SUPERSEDED',
                },
                _ => {
                  'key': 'CELL:$localDraft:WED:s1',
                  'outcome': 'REJECTED',
                  'reason': 'TIMETABLE_OUT_OF_PROGRAMME',
                },
              },
          ],
        };
      });
      final handler = TimetableDraftOutboxHandler(
        dio: Dio()..httpClientAdapter = adapter,
        dao: TimetableDraftDao(db),
        outbox: OutboxDao(db),
        requiredAuth: const {},
        now: () => now.millisecondsSinceEpoch,
      );
      final entry = (await OutboxDao(
        db,
      ).pendingReady(now.millisecondsSinceEpoch)).single;
      final result = await handler.dispatch(entry);
      expect(result.outcome, OutboxDispatchOutcome.acked);
      final v = await view();
      expect(v.header!.draftId, 'canon');
      expect(v.header!.pendingGesture, isNull);
      final byDay = {for (final c in v.draft) c.day: c};
      expect(byDay[Weekday.tue]!.superseded, isTrue);
      expect(byDay[Weekday.wed]!.syncState, RecordSyncState.failed);
      expect(byDay[Weekday.wed]!.errorCode, 'TIMETABLE_OUT_OF_PROGRAMME');
    },
  );

  test('un tirage n’écrase ni une case ni un geste en attente', () async {
    await editor.start(await view());
    final draft = (await view()).header!.draftId!;
    await editor.setCells(await view(), [
      const CellChange(Weekday.tue, _slot, _math),
    ]);
    final serverCell = ClassTimetableCell(
      id: 'x',
      classroomId: 'c7a',
      classroomLabel: '7e A',
      status: TimetableCellStatus.draft,
      draftId: draft,
      day: Weekday.tue,
      slotId: 's1',
      range: const MinuteRange(450, 500),
    );
    await TimetableDao(db).applyCells([
      PulledTimetableRow(
        TimetableWire.cell({
          'id': 'srv',
          'classroomId': 'c7a',
          'status': 'DRAFT',
          'draftId': draft,
          'day': 'TUE',
          'slotId': 's1',
          'startMinute': 450,
          'endMinute': 500,
        }).value,
        9,
      ),
    ], 9);
    expect(serverCell.isEmpty, isTrue);
    await TimetableDao(db).applyHeaders([
      const PulledTimetableRow(
        ClassTimetableHeader(
          id: 'h',
          classroomId: 'c7a',
          academicYearId: 'y',
          revision: 2,
          publishedVersion: 1,
        ),
        9,
      ),
    ], 9);
    final v = await view();
    expect(v.header!.pendingGesture, 'START');
    expect(v.header!.draftId, draft);
    expect(v.draft.single.coursId, 'math');
  });

  test(
    'brouillon clos entre-temps : les gestes restent, à reprendre ou ignorer',
    () async {
      await editor.start(await view());
      await editor.setCells(await view(), [
        const CellChange(Weekday.tue, _slot, _math),
      ]);
      final dao = TimetableDraftDao(db);
      final cell = (await dao.pending()).whereType<CellGesture>().single;
      await dao.gestureRejected(cell, 'TIMETABLE_DRAFT_ENDED');
      final ended = await dao.endedCells('c7a');
      expect(ended.single.day, Weekday.tue);
      await dao.discard(ended);
      expect(await dao.endedCells('c7a'), isEmpty);
    },
  );
}
