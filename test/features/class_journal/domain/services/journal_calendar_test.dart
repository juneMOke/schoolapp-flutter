import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_calendar.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

void main() {
  // Rentrée le lundi 5 octobre 2026 ; cours le lundi et le mercredi.
  final calendar = JournalCalendar(
    courseDays: const {Weekday.mon, Weekday.wed},
    yearStart: DateTime(2026, 10, 5),
    yearEnd: DateTime(2027, 6, 30),
  );

  group('N° de page', () {
    test('rang parmi les jours de cours depuis la rentrée', () {
      expect(calendar.pageNumber(DateTime(2026, 10, 5)), 1);
      expect(calendar.pageNumber(DateTime(2026, 10, 7)), 2);
      expect(calendar.pageNumber(DateTime(2026, 10, 12)), 3);
    });

    test('rien un jour sans cours, avant la rentrée, ou sans rentrée', () {
      expect(calendar.pageNumber(DateTime(2026, 10, 6)), isNull);
      expect(calendar.pageNumber(DateTime(2026, 9, 28)), isNull);
      expect(
        const JournalCalendar(
          courseDays: {Weekday.mon},
        ).pageNumber(DateTime(2026, 10, 5)),
        isNull,
      );
    });
  });

  group('prochain jour de cours', () {
    test('le samedi mène au lundi suivant', () {
      expect(
        calendar.nextCourseDay(DateTime(2026, 10, 10)),
        DateTime(2026, 10, 12),
      );
    });

    test('aucun au-delà de la fin d\'année, ni sans jour de cours', () {
      expect(calendar.nextCourseDay(DateTime(2027, 6, 30)), isNull);
      expect(
        const JournalCalendar(
          courseDays: {},
        ).nextCourseDay(DateTime(2026, 10, 5)),
        isNull,
      );
    });
  });

  test('une rentrée lue d\'un instant UTC compte dès son premier jour', () {
    for (final iso in ['2026-10-05T00:00:00Z', '2026-10-04T23:00:00Z']) {
      final utc = JournalCalendar(
        courseDays: const {Weekday.mon, Weekday.wed},
        yearStart: DateTime.parse(iso),
      );
      expect(utc.pageNumber(DateTime(2026, 10, 5)), 1, reason: iso);
    }
  });

  test('le dimanche n\'est jamais un jour de cours', () {
    expect(JournalCalendar.weekdayOf(DateTime(2026, 10, 11)), isNull);
    expect(JournalCalendar.weekdayOf(DateTime(2026, 10, 12)), Weekday.mon);
  });
}
