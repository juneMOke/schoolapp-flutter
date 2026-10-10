import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/load_journal_day_use_case.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

import '../../journal_fixtures.dart';

class _MockSchedule extends Mock implements ScheduleRepository {}

class _MockCourses extends Mock implements CourseRepository {}

class _MockJournal extends Mock implements JournalRepository {}

class _MockProgramme extends Mock implements ProgrammeRepository {}

void main() {
  late _MockSchedule schedule;
  late _MockCourses courses;
  late _MockJournal journal;
  late _MockProgramme programme;
  late LoadJournalDayUseCase load;

  // Mercredi 14 octobre 2026, 9 h à Kinshasa.
  final now = DateTime.utc(2026, 10, 14, 8).millisecondsSinceEpoch;
  final wednesday = DateTime(2026, 10, 14);
  final year = AcademicYear(
    id: 'ay',
    name: '2026-2027',
    startDate: DateTime(2026, 10, 5),
    current: true,
  );

  setUpAll(() => registerFallbackValue(<String>{}));

  setUp(() {
    schedule = _MockSchedule();
    courses = _MockCourses();
    journal = _MockJournal();
    programme = _MockProgramme();
    load = LoadJournalDayUseCase(
      schedule: schedule,
      courses: courses,
      journal: journal,
      programme: programme,
      now: () => now,
    );
    when(() => schedule.getMyTimetable('ay')).thenAnswer(
      (_) async => Right(timetableOf({(Weekday.wed, 's1'): 'maths-7a'})),
    );
    when(() => courses.getMyCourses()).thenAnswer(
      (_) async => const Right([
        CourseSummary(
          classroom: ClassroomSummary(
            id: 'room-6b',
            schoolLevelId: 'l',
            name: '6e B',
            capacity: 40,
            totalCount: 0,
            femaleCount: 0,
            maleCount: 0,
          ),
          courses: [CourseRef(id: 'physique-6b', label: 'Physique')],
        ),
      ]),
    );
  });

  test('aujourd\'hui est le jour de l\'école', () {
    expect(load.today(), wednesday);
  });

  test(
    'compose la page : séances, entrées des cours du prof, chapitres',
    () async {
      when(() => journal.entriesOfCours(any())).thenAnswer(
        (_) async => Right([
          entryOf(
            coursId: 'maths-7a',
            date: wednesday,
            slot: 's1',
            chapitreId: 'ch-b',
          ),
          entryOf(coursId: 'physique-6b', date: wednesday, slot: 's3'),
        ]),
      );
      when(() => programme.loadProgramme('maths-7a')).thenAnswer(
        (_) async => const Right(
          Programme(
            coursId: 'maths-7a',
            chapitres: [
              ProgrammeChapitre(
                chapitre: Chapitre(
                  id: 'ch-a',
                  coursId: 'maths-7a',
                  ordre: 0,
                  titre: 'A',
                ),
              ),
              ProgrammeChapitre(
                chapitre: Chapitre(
                  id: 'ch-b',
                  coursId: 'maths-7a',
                  ordre: 5,
                  titre: 'B',
                ),
              ),
            ],
          ),
        ),
      );

      final day = (await load(
        wednesday,
        year: year,
      )).getOrElse(() => throw StateError('échec'));

      final queried =
          verify(() => journal.entriesOfCours(captureAny())).captured.single
              as Set<String>;
      expect(queried, {'maths-7a', 'physique-6b'});
      expect(day.lines.first.chapter?.number, 2);
      expect(day.lines.last.subjectLabel, 'Physique');
      expect(day.lines.last.scheduled, isFalse);
      expect(day.pageNumber, 2);
      verifyNever(() => programme.loadProgramme('physique-6b'));
    },
  );

  test('un emploi du temps illisible fait échouer la page', () async {
    when(
      () => schedule.getMyTimetable('ay'),
    ).thenAnswer((_) async => const Left(StorageFailure('ko')));

    expect((await load(wednesday, year: year)).isLeft(), isTrue);
    verifyNever(() => journal.entriesOfCours(any()));
  });

  test('des cours illisibles ne font pas échouer la page', () async {
    when(
      () => courses.getMyCourses(),
    ).thenAnswer((_) async => const Left(StorageFailure('ko')));
    when(
      () => journal.entriesOfCours(any()),
    ).thenAnswer((_) async => const Right([]));

    final result = await load(wednesday, year: year);

    expect(result.isRight(), isTrue);
  });
}
