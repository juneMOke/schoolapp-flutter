import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_reference_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/school_closed_day_reader.dart';
import 'package:school_app_flutter/features/school_calendar/data/wire/calendar_wire.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  setUp(() async => db = await openFullOfflineDb());
  tearDown(() => db.close());

  Future<void> seed(CalendarStatus status) async {
    final dao = CalendarReferenceDao(db);
    await dao.applyFrameworks(
      [
        Pulled(
          NationalFramework(
            id: 'fw',
            yearLabel: '2025-2026',
            version: 1,
            startDate: DateTime.utc(2025, 9, 1),
            endDate: DateTime.utc(2026, 7, 3),
            items: [
              CalendarElement(
                id: 'ind',
                source: CalendarSource.national,
                nature: CalendarNature.publicHoliday,
                title: 'Indépendance',
                startDate: DateTime.utc(2026, 6, 30),
                endDate: DateTime.utc(2026, 6, 30),
              ),
              CalendarElement(
                id: 'sec',
                source: CalendarSource.national,
                nature: CalendarNature.holidayBreak,
                title: 'Congé du secondaire',
                startDate: DateTime.utc(2026, 6, 1),
                endDate: DateTime.utc(2026, 6, 5),
                scope: const CycleScope('SEC'),
              ),
            ],
          ),
          1,
        ),
      ],
      schoolId: 's',
      nowMs: 1,
    );
    await dao.applyCalendars(
      [
        Pulled(
          SchoolCalendar(
            id: 'cal',
            yearLabel: '2025-2026',
            status: status,
            startDate: DateTime.utc(2025, 9, 1),
            endDate: DateTime.utc(2026, 7, 3),
            framework: FrameworkState.integrated,
            revision: 1,
          ),
          1,
        ),
      ],
      schoolId: 's',
      nowMs: 1,
    );
  }

  test(
    'E13 : un férié de toute l’école ferme la journée de l’enseignant',
    () async {
      await seed(CalendarStatus.published);
      final reader = SchoolClosedDayReader(db, schoolId: () => 's');
      expect(
        (await reader.closingOf(DateTime(2026, 6, 30)))?.title,
        'Indépendance',
      );
      expect(await reader.closingOf(DateTime(2026, 6, 29)), isNull);
    },
  );

  test('un congé d’un seul cycle ne ferme pas la journée', () async {
    await seed(CalendarStatus.published);
    final reader = SchoolClosedDayReader(db, schoolId: () => 's');
    expect(await reader.closingOf(DateTime(2026, 6, 2)), isNull);
  });

  test('un brouillon de calendrier ne se voit pas ailleurs (R18)', () async {
    await seed(CalendarStatus.draft);
    final reader = SchoolClosedDayReader(db, schoolId: () => 's');
    expect(await reader.closingOf(DateTime(2026, 6, 30)), isNull);
  });
}
