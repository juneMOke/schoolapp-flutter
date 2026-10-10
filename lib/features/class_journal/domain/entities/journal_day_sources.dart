import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_calendar.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';

/// Les libellés d'un cours du professeur.
class JournalCourse {
  final String subjectLabel;
  final String classroomLabel;

  const JournalCourse({
    required this.subjectLabel,
    required this.classroomLabel,
  });
}

/// Un chapitre tel que l'étiquette le montre : son numéro (rang dans le
/// programme, à partir de 1) et son titre.
class JournalChapterRef {
  final int number;
  final String title;

  const JournalChapterRef({required this.number, required this.title});
}

/// Tout ce qu'il faut, déjà lu sur la tablette, pour composer une page.
class JournalDaySources {
  /// L'emploi du temps actuel du professeur, tous créneaux de l'école.
  final WeeklyTimetable timetable;

  /// Les cours du professeur, par id — libellés d'une séance qui n'est plus à
  /// l'emploi du temps.
  final Map<String, JournalCourse> courses;

  /// Toutes les entrées de ses cours.
  final List<JournalEntry> entries;

  /// Les chapitres cités par ces entrées, par id. Absent : chapitre supprimé,
  /// la séance se lit hors programme.
  final Map<String, JournalChapterRef> chapters;
  final JournalCalendar calendar;

  const JournalDaySources({
    required this.timetable,
    required this.courses,
    required this.entries,
    required this.chapters,
    required this.calendar,
  });
}
