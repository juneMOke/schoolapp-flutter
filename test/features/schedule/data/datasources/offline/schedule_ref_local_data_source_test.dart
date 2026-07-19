import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_time_slot_row.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/schedule_pull_models.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  late ScheduleRefLocalDataSource local;

  setUp(() async {
    db = await openFullOfflineDb();
    local = ScheduleRefLocalDataSource(db);
  });

  tearDown(() async => db.close());

  RefTimeSlotRow slot(String id, {int order = 1, String start = '08:00'}) =>
      RefTimeSlotRow(
        id: id,
        slotOrder: order,
        startTime: start,
        endTime: '08:50',
        syncedAt: 100,
      );

  group('applyPulledTimeSlots', () {
    test('upsert idempotent par uuid (REPLACE) + tri par slot_order', () async {
      await local.applyPulledTimeSlots([
        slot('t2', order: 2),
        slot('t1', order: 1),
      ]);
      // Re-pull du même id avec une valeur changée → remplacé, pas dupliqué.
      await local.applyPulledTimeSlots([slot('t1', order: 1, start: '07:55')]);

      final rows = await local.getTimeSlots();
      expect(rows.map((r) => r.id).toList(), ['t1', 't2'], reason: 'ordre');
      expect(rows.first.startTime, '07:55', reason: 'remplacé');
      expect(rows.length, 2, reason: 'pas de doublon');
    });
  });

  group('parsing tolérant (anti poison-page)', () {
    test('une ligne malformée est écartée, les valides sont conservées', () {
      final dto = TimeSlotPageDto.fromJson({
        'items': [
          {
            'id': 't1',
            'slotOrder': 1,
            'startTime': '08:00',
            'endTime': '08:50',
            'serverUpdatedAt': '2026-07-19T09:00:00Z',
          },
          {'id': 't2', 'slotOrder': 2}, // startTime/endTime manquants → écartée
          {
            'id': 't3',
            'slotOrder': 3,
            'startTime': '09:00',
            'endTime': '09:50',
            'serverUpdatedAt': '2026-07-19T09:00:00Z',
          },
        ],
        'hasMore': false,
        'serverTime': '2026-07-19T10:00:00Z',
      });

      expect(dto.items.map((i) => i.id).toList(), ['t1', 't3']);
    });

    test('serverUpdatedAt ISO naïf est ré-ancré en UTC', () {
      final row = const TimeSlotDeltaDto(
        id: 't1',
        slotOrder: 1,
        startTime: '08:00',
        endTime: '08:50',
        serverUpdatedAt: '2026-07-19T09:00:00', // naïf (sans Z)
      ).toLocalRow(100);

      expect(
        row.serverUpdatedAt,
        DateTime.utc(2026, 7, 19, 9).millisecondsSinceEpoch,
      );
    });
  });
}
