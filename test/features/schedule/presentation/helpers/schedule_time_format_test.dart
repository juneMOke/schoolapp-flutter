import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';

TimeSlot _slot(String start, String end, {String? label, int order = 0}) =>
    TimeSlot(
      id: 's-$order',
      order: order,
      startTime: start,
      endTime: end,
      label: label,
    );

TimetableCell _cell(String id) => TimetableCell(
  sessionId: 'sess-$id',
  coursId: 'cours-$id',
  classroomId: 'class-$id',
  classroomLabel: 'Classe $id',
  teacherId: 't-1',
  teacherLabel: 'Enseignant',
  subjectLabel: 'Matière $id',
);

void main() {
  group('hourMinute', () {
    test('tronque HH:mm:ss en HH:mm', () {
      expect(ScheduleTimeFormat.hourMinute('08:00:00'), '08:00');
    });

    test('normalise et complète les zéros', () {
      expect(ScheduleTimeFormat.hourMinute('8:5'), '08:05');
    });

    test('repli sur la valeur brute si non parsable', () {
      expect(ScheduleTimeFormat.hourMinute('xx'), 'xx');
    });
  });

  group('slotDurationMinutes', () {
    test('calcule la durée en minutes', () {
      expect(
        ScheduleTimeFormat.slotDurationMinutes(_slot('08:00:00', '08:50:00')),
        50,
      );
    });

    test('repli sur 0 si fin ≤ début', () {
      expect(
        ScheduleTimeFormat.slotDurationMinutes(_slot('09:00:00', '08:00:00')),
        0,
      );
    });

    test('repli sur 0 si non parsable', () {
      expect(ScheduleTimeFormat.slotDurationMinutes(_slot('', '')), 0);
    });
  });

  group('todayWeekday', () {
    test('mercredi 10 juin 2026 → wed', () {
      expect(
        ScheduleTimeFormat.todayWeekday(reference: DateTime(2026, 6, 10)),
        Weekday.wed,
      );
    });

    test('samedi → sat', () {
      expect(
        ScheduleTimeFormat.todayWeekday(reference: DateTime(2026, 6, 13)),
        Weekday.sat,
      );
    });

    test('dimanche (hors grille) → null', () {
      expect(
        ScheduleTimeFormat.todayWeekday(reference: DateTime(2026, 6, 14)),
        isNull,
      );
    });
  });

  group('compteurs', () {
    final timetable = WeeklyTimetable(
      academicYearId: 'ay-1',
      days: const [Weekday.mon, Weekday.tue],
      rows: [
        TimetableRow(
          timeSlot: _slot('08:00:00', '08:50:00', order: 0),
          cells: {Weekday.mon: _cell('a'), Weekday.tue: _cell('b')},
        ),
        TimetableRow(
          timeSlot: _slot('08:50:00', '09:40:00', order: 1),
          cells: {Weekday.mon: _cell('c'), Weekday.tue: null},
        ),
      ],
    );

    test('sessionCount ne compte que les cases occupées', () {
      expect(ScheduleTimeFormat.sessionCount(timetable), 3);
    });

    test('totalCourseHours somme les durées des cases occupées', () {
      // 3 séances × 50 min = 150 min = 2,5 h.
      expect(ScheduleTimeFormat.totalCourseHours(timetable), 2.5);
    });

    test('totalCourseHours arrondit au dixième (spec §2)', () {
      // 5 séances × 50 min = 250 min = 4,1666… h → arrondi 0,1 = 4,2.
      final odd = WeeklyTimetable(
        academicYearId: 'ay-1',
        days: const [
          Weekday.mon,
          Weekday.tue,
          Weekday.wed,
          Weekday.thu,
          Weekday.fri,
        ],
        rows: [
          TimetableRow(
            timeSlot: _slot('08:00:00', '08:50:00', order: 0),
            cells: {
              Weekday.mon: _cell('a'),
              Weekday.tue: _cell('b'),
              Weekday.wed: _cell('c'),
              Weekday.thu: _cell('d'),
              Weekday.fri: _cell('e'),
            },
          ),
        ],
      );
      expect(ScheduleTimeFormat.totalCourseHours(odd), 4.2);
    });
  });
}
