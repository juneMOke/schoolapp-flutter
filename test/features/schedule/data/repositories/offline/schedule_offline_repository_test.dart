import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_offline_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockOnlineSchedule extends Mock implements ScheduleRepository {}

void main() {
  late Database db;
  late ScheduleOfflineRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    repo = ScheduleOfflineRepositoryImpl(
      online: MockOnlineSchedule(),
      refLocalDataSource: ScheduleRefLocalDataSource(db),
      currentUser: CurrentUserContext()..set('me'),
    );
  });

  tearDown(() async => db.close());

  Future<void> insertSlot(String id, int order, String start) =>
      db.insert('ref_time_slots', {
        'id': id,
        'slot_order': order,
        'start_time': start,
        'end_time': '$start-fin',
        'synced_at': 1,
      });

  Future<void> insertSession(
    String id,
    String coursId,
    String slotId,
    String day,
    String teacher,
  ) => db.insert('ref_recurring_sessions', {
    'id': id,
    'academic_year_id': 'ay-1',
    'cours_id': coursId,
    'time_slot_id': slotId,
    'day_of_week': day,
    'teacher_id': teacher,
    'classroom_id': 'class-1',
    'teacher_label': 'M. Moi',
    'classroom_label': '3e A',
    'subject_label': 'Maths',
    'synced_at': 1,
  });

  test('getMyTimetable : grille créneau×jour, sans filtre d\'identité côté '
      'client (DF-K, séances déjà scopées enseignant par le pull)', () async {
    await insertSlot('t1', 1, '08:00');
    await insertSlot('t2', 2, '09:00');
    await insertSession('s1', 'co1', 't1', 'MON', 'me');
    await insertSession('s2', 'co2', 't2', 'TUE', 'me');

    final result = await repo.getMyTimetable('ay-1');

    final tt = result.getOrElse(() => fail('Left'));
    expect(tt.teacherId, 'me');
    expect(tt.days, [Weekday.mon, Weekday.tue]);
    expect(tt.rows.length, 2);
    expect(tt.rows.first.timeSlot.id, 't1', reason: 'ordonné par slot_order');

    final row1 = tt.rows.firstWhere((r) => r.timeSlot.id == 't1');
    expect(row1.cells[Weekday.mon]!.coursId, 'co1');
    expect(row1.cells[Weekday.tue], isNull);

    final row2 = tt.rows.firstWhere((r) => r.timeSlot.id == 't2');
    expect(row2.cells[Weekday.tue]!.coursId, 'co2');
    expect(row2.cells[Weekday.mon], isNull);
  });
}
