import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_read_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_direction_repository.dart';
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
  final ProgrammeRepository _programme;
  final Clock _now;

  const LoadTeacherJournalDayUseCase({
    required this.teacherId,
    required JournalDirectionRepository direction,
    required ProgrammeRepository programme,
    Clock now = systemClock,
  }) : _direction = direction,
       _programme = programme,
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
      final chapters = await _chaptersOf(lines);
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
                chapter: chapters[line.entry?.chapitreId],
              ),
          ],
        ),
      );
    },
  );

  /// Les chapitres cités, lus dans le programme en ligne de leur cours : leur
  /// numéro est leur rang. Un programme illisible laisse la séance sans
  /// étiquette.
  Future<Map<String, JournalChapterTag>> _chaptersOf(
    List<JournalReadLine> lines,
  ) async {
    final cours = {
      for (final line in lines)
        if (line.entry?.chapitreId != null) line.coursId,
    };
    final tags = <String, JournalChapterTag>{};
    for (final coursId in cours) {
      (await _programme.loadProgramme(coursId)).fold((_) {}, (programme) {
        final rows = programme.chapitres;
        for (var i = 0; i < rows.length; i++) {
          tags[rows[i].chapitre.id] = JournalChapterTag(
            number: i + 1,
            title: rows[i].chapitre.titre,
          );
        }
      });
    }
    return tags;
  }
}
