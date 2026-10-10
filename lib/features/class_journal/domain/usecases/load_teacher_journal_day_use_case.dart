import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_direction_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_chapter_refs.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_status_rule.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/journal_day_loader.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';

/// La journée d'un professeur, lue **en ligne** par la direction : le serveur
/// assemble les lignes, la tablette en dérive les statuts et les étiquettes.
/// Sans grille de sonnerie ni journal complet du cours, ni récréation, ni
/// « séance n », ni N° de page.
class LoadTeacherJournalDayUseCase implements JournalDayLoader {
  final String teacherId;
  final JournalDirectionRepository _direction;

  /// Les programmes lus en ligne, retenus pour la vie de ce professeur à
  /// l'écran : une page suivante ne les relit pas.
  final JournalChapterRefs _chapters;
  final Clock _now;

  LoadTeacherJournalDayUseCase({
    required this.teacherId,
    required JournalDirectionRepository direction,
    required ProgrammeRepository programme,
    Clock now = systemClock,
  }) : _direction = direction,
       _chapters = JournalChapterRefs(programme, remember: true),
       _now = now;

  @override
  DateTime today() =>
      SchoolTime.today(DateTime.fromMillisecondsSinceEpoch(_now()));

  @override
  Future<Either<Failure, JournalDay>> call(
    DateTime date, {
    required AcademicYear year,
  }) async => (await _direction.dayOf(teacherId, date)).fold(
    (failure) async => Left(failure),
    (lines) async {
      final chapters = await _chapters.of({
        for (final line in lines)
          if (line.entry?.chapitreId != null) line.coursId,
      });
      final today = this.today();
      return Right(
        JournalDay(
          date: date,
          lines: [
            for (final line in lines)
              JournalLine(
                timeSlotId: line.timeSlotId,
                slot: line.slot,
                coursId: line.coursId,
                subjectLabel: line.subjectLabel,
                classroomLabel: line.classroomLabel,
                entry: line.entry,
                scheduled: line.inTimetable,
                status: JournalStatusRule.of(
                  line.entry,
                  date: date,
                  today: today,
                ),
                chapter: switch (chapters[line.entry?.chapitreId]) {
                  final ref? => JournalChapterTag(
                    number: ref.number,
                    title: ref.title,
                  ),
                  null => null,
                },
              ),
          ],
        ),
      );
    },
  );
}
