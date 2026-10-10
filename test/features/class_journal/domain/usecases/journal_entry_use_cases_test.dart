import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/journal_entry_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';

import '../../journal_fixtures.dart';

class _MockProgramme extends Mock implements ProgrammeRepository {}

class _MockJournal extends Mock implements JournalRepository {}

void main() {
  late _MockProgramme programme;
  late _MockJournal journal;
  late LoadJournalFormSeedUseCase seed;

  setUp(() {
    programme = _MockProgramme();
    journal = _MockJournal();
    seed = LoadJournalFormSeedUseCase(programme: programme, journal: journal);
    when(() => journal.entriesOfCours({'c'})).thenAnswer(
      (_) async => Right([
        entryOf(
          coursId: 'c',
          date: DateTime(2026, 10, 12),
          slot: 's1',
          fields: const JournalFields(cb: 'Résoudre'),
        ),
      ]),
    );
  });

  test('les chapitres du cours dans l\'ordre, et la dernière C.B', () async {
    when(() => programme.loadProgramme('c')).thenAnswer(
      (_) async => const Right(
        Programme(
          coursId: 'c',
          chapitres: [
            ProgrammeChapitre(
              chapitre: Chapitre(id: 'a', coursId: 'c', ordre: 0, titre: 'A'),
            ),
          ],
        ),
      ),
    );

    final result = await seed('c', slotOrder: const {});

    expect(result.chapters.single.id, 'a');
    expect(result.lastCb, 'Résoudre');
  });

  test('un programme illisible laisse « Hors programme » seul', () async {
    when(
      () => programme.loadProgramme('c'),
    ).thenAnswer((_) async => const Left(StorageFailure('ko')));

    final result = await seed('c', slotOrder: const {});

    expect(result.chapters, isEmpty);
    expect(result.lastCb, 'Résoudre');
  });
}
