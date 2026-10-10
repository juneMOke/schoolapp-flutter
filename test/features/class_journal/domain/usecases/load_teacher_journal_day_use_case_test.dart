import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_read_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_direction_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/load_teacher_journal_day_use_case.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';

import '../../journal_fixtures.dart';

class _MockDirection extends Mock implements JournalDirectionRepository {}

class _MockProgramme extends Mock implements ProgrammeRepository {}

void main() {
  late _MockDirection direction;
  late _MockProgramme programme;
  late LoadTeacherJournalDayUseCase load;
  // Mercredi 14 octobre 2026, 9 h à Kinshasa.
  final now = DateTime.utc(2026, 10, 14, 8).millisecondsSinceEpoch;
  final tuesday = DateTime(2026, 10, 13);
  const year = AcademicYear(id: 'ay', name: '2026-2027', current: true);

  setUp(() {
    direction = _MockDirection();
    programme = _MockProgramme();
    load = LoadTeacherJournalDayUseCase(
      teacherId: 't',
      direction: direction,
      programme: programme,
      now: () => now,
    );
  });

  test('statuts dérivés, étiquette sans « séance n », pas de N°', () async {
    when(() => direction.dayOf('t', tuesday)).thenAnswer(
      (_) async => Right([
        JournalReadLine(
          coursId: 'c-1',
          subjectLabel: 'Maths',
          classroomLabel: '7e A',
          slot: kSchoolSlots.first,
          timeSlotId: 's1',
          inTimetable: true,
          entry: entryOf(
            coursId: 'c-1',
            date: tuesday,
            slot: 's1',
            chapitreId: 'ch',
          ),
        ),
        JournalReadLine(
          coursId: 'c-2',
          subjectLabel: 'Physique',
          classroomLabel: '6e B',
          slot: kSchoolSlots[1],
          timeSlotId: 's2',
          inTimetable: true,
        ),
      ]),
    );
    when(() => programme.loadProgramme('c-1')).thenAnswer(
      (_) async => const Right(
        Programme(
          coursId: 'c-1',
          chapitres: [
            ProgrammeChapitre(
              chapitre: Chapitre(
                id: 'ch',
                coursId: 'c-1',
                ordre: 0,
                titre: 'Aires',
              ),
            ),
          ],
        ),
      ),
    );

    final day = (await load(
      tuesday,
      year: year,
    )).getOrElse(() => throw StateError('échec'));

    expect(day.lines.first.status, JournalStatus.filled);
    expect(day.lines.first.chapter?.number, 1);
    expect(day.lines.first.chapter?.seanceNo, isNull);
    expect(day.lines.last.status, JournalStatus.missing);
    expect(day.pageNumber, isNull);
  });

  test('un échec de lecture en ligne remonte tel quel', () async {
    when(
      () => direction.dayOf('t', tuesday),
    ).thenAnswer((_) async => const Left(UnauthorizedFailure()));

    final result = await load(tuesday, year: year);

    expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
  });
}
