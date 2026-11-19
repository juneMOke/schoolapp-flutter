import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_timetable_reader.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  setUp(() async => db = await openFullOfflineDb());
  tearDown(() => db.close());

  test('une classe inconnue dans l’adresse ne laisse pas un chargement sans '
      'fin : l’adresse se corrige', () async {
    final cubit = ClassTimetableCubit(
      ClassTimetableReader(db, SyncMetaDao(db), schoolId: () => 's'),
      schoolToday: () => DateTime.utc(2026, 10, 1),
    );
    await cubit.load();
    await cubit.selectClass('fermee');
    expect(cubit.state.status, ClassTimetableStatus.ready);
    expect(cubit.state.classroomId, isNull);
    expect(cubit.state.view, isNull);
    await cubit.close();
  });

  test('changer de classe garde la semaine choisie', () async {
    final cubit = ClassTimetableCubit(
      ClassTimetableReader(db, SyncMetaDao(db), schoolId: () => 's'),
      schoolToday: () => DateTime.utc(2026, 10, 1),
    );
    await cubit.load();
    await cubit.setWeek(DateTime.utc(2026, 10, 14));
    await cubit.selectClass('autre');
    expect(cubit.state.week, DateTime.utc(2026, 10, 12));
    await cubit.close();
  });
}
