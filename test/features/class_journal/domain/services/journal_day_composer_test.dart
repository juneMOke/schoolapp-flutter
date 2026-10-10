import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day_sources.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_calendar.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_day_composer.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

import '../../journal_fixtures.dart';

void main() {
  // Mercredi 14 octobre 2026 ; rentrée le lundi 5.
  final wednesday = DateTime(2026, 10, 14);
  final timetable = timetableOf({
    (Weekday.wed, 's1'): 'maths-7a',
    (Weekday.wed, 's4'): 'maths-8a',
    (Weekday.mon, 's2'): 'maths-7a',
  });

  JournalDay compose({
    List<JournalEntry> entries = const [],
    Map<String, JournalChapterRef> chapters = const {},
    DateTime? date,
  }) => JournalDayComposer.compose(
    JournalDaySources(
      timetable: timetable,
      courses: const {
        'physique-6b': JournalCourse(
          subjectLabel: 'Physique',
          classroomLabel: '6e B',
        ),
      },
      entries: entries,
      chapters: chapters,
      calendar: JournalCalendar(
        courseDays: timetable.days.toSet(),
        yearStart: DateTime(2026, 10, 5),
      ),
    ),
    date: date ?? wednesday,
    today: wednesday,
  );

  test('une ligne par séance du jour, triée par créneau, pause comprise', () {
    final day = compose();

    expect(day.lines.map((l) => l.coursId), ['maths-7a', 'maths-8a']);
    expect(day.lines.every((l) => l.status == JournalStatus.toPrepare), isTrue);
    expect(day.lines.first.breakBefore, isNull);
    expect(day.lines.last.breakBefore?.start, '10:00:00');
    // Lundi 5, mercredi 7, lundi 12, mercredi 14.
    expect(day.pageNumber, 4);
  });

  test('une entrée hors emploi du temps actuel reste lisible à sa date', () {
    final orphan = entryOf(coursId: 'physique-6b', date: wednesday, slot: 's2');
    final day = compose(entries: [orphan]);

    final line = day.lines.singleWhere((l) => l.coursId == 'physique-6b');
    expect(line.scheduled, isFalse);
    expect(line.subjectLabel, 'Physique');
    expect(line.entry, orphan);
    expect(day.lines.map((l) => l.slot.id), ['s1', 's2', 's4']);
  });

  test('une entrée vidée ne ressuscite pas une séance retirée', () {
    final cleared = entryOf(
      coursId: 'physique-6b',
      date: wednesday,
      slot: 's2',
      fields: JournalFields.empty,
    );

    expect(compose(entries: [cleared]).lines, hasLength(2));
  });

  test(
    'l\'étiquette chapitre : numéro, titre, séance n ; chapitre absent = hors programme',
    () {
      final monday = DateTime(2026, 10, 12);
      final day = compose(
        entries: [
          entryOf(
            coursId: 'maths-7a',
            date: monday,
            slot: 's2',
            chapitreId: 'ch3',
          ),
          entryOf(
            coursId: 'maths-7a',
            date: wednesday,
            slot: 's1',
            chapitreId: 'ch3',
          ),
          entryOf(
            coursId: 'maths-8a',
            date: wednesday,
            slot: 's4',
            chapitreId: 'gone',
          ),
        ],
        chapters: const {'ch3': JournalChapterRef(number: 3, title: 'Aires')},
      );

      final tag = day.lines.first.chapter;
      expect(tag?.number, 3);
      expect(tag?.seanceNo, 2);
      expect(day.lines.last.chapter, isNull);
      expect(day.filledCount, 2);
      expect(day.isComplete, isTrue);
    },
  );

  test('un jour sans cours : vide, prochain jour de cours, pas de N°', () {
    final day = compose(date: DateTime(2026, 10, 15));

    expect(day.isEmpty, isTrue);
    expect(day.pageNumber, isNull);
    expect(day.nextCourseDay, DateTime(2026, 10, 19));
  });
}
