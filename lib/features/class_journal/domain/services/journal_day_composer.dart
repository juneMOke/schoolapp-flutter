import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day_sources.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_breaks.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_calendar.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_seance_numbers.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_status_rule.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';

/// Compose la page d'un jour.
///
/// Les lignes = les séances de ce jour de la semaine à l'emploi du temps
/// actuel **et** les entrées déjà saisies à cette date. L'emploi du temps ne
/// garde pas d'historique : sans la seconde moitié, un changement d'emploi du
/// temps ferait disparaître des pages déjà écrites. Une entrée vidée, elle,
/// ne ressuscite pas une séance retirée.
abstract final class JournalDayComposer {
  static JournalDay compose(
    JournalDaySources sources, {
    required DateTime date,
    required DateTime today,
  }) {
    final rows = sources.timetable.rows;
    final schoolSlots = [for (final row in rows) row.timeSlot];
    final slotById = {for (final s in schoolSlots) s.id: s};
    final slotOrder = {for (final s in schoolSlots) s.id: s.order};
    final onDate = {
      for (final e in sources.entries)
        if (e.date == date) _key(e.coursId, e.timeSlotId): e,
    };
    final numbers = JournalSeanceNumbers.of(
      sources.entries,
      slotOrder: slotOrder,
    );

    JournalLine lineOf(
      TimeSlot slot,
      String coursId,
      JournalCourse? course, {
      required bool scheduled,
    }) {
      final entry = onDate[_key(coursId, slot.id)];
      return JournalLine(
        slot: slot,
        coursId: coursId,
        subjectLabel: course?.subjectLabel ?? '',
        classroomLabel: course?.classroomLabel ?? '',
        entry: entry,
        scheduled: scheduled,
        status: JournalStatusRule.of(entry, date: date, today: today),
        chapter: _tagOf(entry, sources.chapters, numbers),
      );
    }

    final weekday = JournalCalendar.weekdayOf(date);
    final lines = <JournalLine>[];
    final seen = <String>{};
    for (final row in rows) {
      final cell = weekday == null ? null : row.cellFor(weekday);
      if (cell == null) continue;
      seen.add(_key(cell.coursId, row.timeSlot.id));
      final course = JournalCourse(
        subjectLabel: cell.subjectLabel,
        classroomLabel: cell.classroomLabel,
      );
      lines.add(lineOf(row.timeSlot, cell.coursId, course, scheduled: true));
    }
    for (final MapEntry(:key, value: entry) in onDate.entries) {
      final slot = slotById[entry.timeSlotId];
      if (seen.contains(key) || entry.isBlank || slot == null) continue;
      lines.add(
        lineOf(
          slot,
          entry.coursId,
          sources.courses[entry.coursId],
          scheduled: false,
        ),
      );
    }
    lines.sort((a, b) => a.slot.order.compareTo(b.slot.order));

    return JournalDay(
      date: date,
      lines: _withBreaks(lines, schoolSlots),
      pageNumber: sources.calendar.pageNumber(date),
      nextCourseDay: sources.calendar.nextCourseDay(date),
    );
  }

  static String _key(String coursId, String timeSlotId) =>
      '$coursId|$timeSlotId';

  static JournalChapterTag? _tagOf(
    JournalEntry? entry,
    Map<String, JournalChapterRef> chapters,
    Map<String, int> numbers,
  ) {
    final chapter = chapters[entry?.chapitreId];
    if (entry == null || chapter == null) return null;
    return JournalChapterTag(
      number: chapter.number,
      title: chapter.title,
      seanceNo: numbers[entry.id],
    );
  }

  static List<JournalLine> _withBreaks(
    List<JournalLine> lines,
    List<TimeSlot> schoolSlots,
  ) => [
    for (var i = 0; i < lines.length; i++)
      i == 0
          ? lines[i]
          : lines[i].withBreakBefore(
              JournalBreaks.between(
                schoolSlots,
                before: lines[i - 1].slot,
                after: lines[i].slot,
              ),
            ),
  ];
}
