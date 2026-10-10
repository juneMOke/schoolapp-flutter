import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day_sources.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_calendar.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_day_composer.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/journal_day_loader.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

/// La page d'un jour, lue **sur la tablette** : l'emploi du temps actuel du
/// professeur, ses cours (libellés), ses entrées et les chapitres qu'elles
/// citent.
class LoadJournalDayUseCase implements JournalDayLoader {
  final ScheduleRepository _schedule;
  final CourseRepository _courses;
  final JournalRepository _journal;
  final ProgrammeRepository _programme;
  final Clock _now;

  const LoadJournalDayUseCase({
    required ScheduleRepository schedule,
    required CourseRepository courses,
    required JournalRepository journal,
    required ProgrammeRepository programme,
    Clock now = systemClock,
  }) : _schedule = schedule,
       _courses = courses,
       _journal = journal,
       _programme = programme,
       _now = now;

  @override
  DateTime today() =>
      SchoolTime.today(DateTime.fromMillisecondsSinceEpoch(_now()));

  @override
  Future<Either<Failure, JournalDay>> call(
    DateTime date, {
    required AcademicYear year,
  }) async => (await _schedule.getMyTimetable(year.id)).fold(
    (failure) async => Left(failure),
    (timetable) => _compose(date, year, timetable),
  );

  Future<Either<Failure, JournalDay>> _compose(
    DateTime date,
    AcademicYear year,
    WeeklyTimetable timetable,
  ) async {
    final courses = await _myCourses();
    final coursIds = {...courses.keys, ..._coursOf(timetable)};
    return (await _journal.entriesOfCours(coursIds)).fold(
      (failure) async => Left(failure),
      (entries) async {
        final sources = JournalDaySources(
          timetable: timetable,
          courses: courses,
          entries: entries,
          chapters: await _chaptersCitedOn(date, entries),
          calendar: JournalCalendar(
            courseDays: timetable.days.toSet(),
            yearStart: year.startDate,
            yearEnd: year.endDate,
          ),
        );
        return Right(
          JournalDayComposer.compose(sources, date: date, today: today()),
        );
      },
    );
  }

  /// Les libellés des cours du professeur ; sans eux, une séance qui n'est
  /// plus à l'emploi du temps s'affiche sans libellé, rien de plus grave.
  Future<Map<String, JournalCourse>> _myCourses() async {
    final result = await _courses.getMyCourses();
    return result.fold((_) => const {}, (summaries) {
      return {
        for (final summary in summaries)
          for (final course in summary.courses)
            if (course.hasId)
              course.id: JournalCourse(
                subjectLabel: course.label,
                classroomLabel: summary.classroom.name,
              ),
      };
    });
  }

  static Iterable<String> _coursOf(WeeklyTimetable timetable) => {
    for (final row in timetable.rows)
      for (final cell in row.cells.values)
        if (cell != null) cell.coursId,
  };

  /// Les chapitres cités par les entrées de [date] : leur numéro est leur
  /// rang dans le programme du cours. Un chapitre absent du programme
  /// (supprimé) ne figure pas — la séance se lit hors programme.
  Future<Map<String, JournalChapterRef>> _chaptersCitedOn(
    DateTime date,
    List<JournalEntry> entries,
  ) async {
    final cited = {
      for (final e in entries)
        if (e.date == date && e.chapitreId != null) e.coursId,
    };
    final refs = <String, JournalChapterRef>{};
    for (final coursId in cited) {
      final programme = await _programme.loadProgramme(coursId);
      programme.fold((_) {}, (programme) {
        final rows = programme.chapitres;
        for (var i = 0; i < rows.length; i++) {
          final chapitre = rows[i].chapitre;
          refs[chapitre.id] = JournalChapterRef(
            number: i + 1,
            title: chapitre.titre,
          );
        }
      });
    }
    return refs;
  }
}
