import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/journal_entry_use_cases.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_field.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_objectif.dart';

import '../../journal_fixtures.dart';

class _MockSeed extends Mock implements LoadJournalFormSeedUseCase {}

class _MockChapter extends Mock implements LoadJournalChapterUseCase {}

class _MockSave extends Mock implements SaveJournalEntryUseCase {}

void main() {
  late _MockSeed seed;
  late _MockChapter chapter;
  late _MockSave save;
  final date = DateTime(2026, 10, 14);

  const planned = Chapitre(
    id: 'ch-1',
    coursId: 'c',
    ordre: 0,
    titre: 'Nombres',
    objectifs: [ChapitreObjectif(id: 'o', texte: 'Compter')],
  );
  const current = Chapitre(
    id: 'ch-2',
    coursId: 'c',
    ordre: 1,
    titre: 'Aires',
    statut: ChapitreStatut.enCours,
    objectifs: [ChapitreObjectif(id: 'o', texte: 'Calculer une aire')],
  );

  JournalLine lineWith({JournalFields? fields, String? chapitreId}) =>
      JournalLine(
        timeSlotId: 's1',
        slot: kSchoolSlots.first,
        coursId: 'c',
        subjectLabel: 'Maths',
        classroomLabel: '7e A',
        status: JournalStatus.toPrepare,
        entry: fields == null
            ? null
            : entryOf(
                coursId: 'c',
                date: date,
                slot: 's1',
                fields: fields,
                chapitreId: chapitreId,
              ),
      );

  setUpAll(() {
    registerFallbackValue(
      JournalSeanceKey(coursId: 'c', date: DateTime(2000), timeSlotId: 's'),
    );
    registerFallbackValue(JournalFields.empty);
  });

  setUp(() {
    seed = _MockSeed();
    chapter = _MockChapter();
    save = _MockSave();
    when(() => seed('c', slotOrder: any(named: 'slotOrder'))).thenAnswer(
      (_) async => const JournalFormSeed(
        chapters: [planned, current],
        lastCb: 'Résoudre',
      ),
    );
    when(() => chapter('ch-1')).thenAnswer((_) async => planned);
    when(() => chapter('ch-2')).thenAnswer((_) async => current);
    when(
      () => save(
        any(),
        fields: any(named: 'fields'),
        chapitreId: any(named: 'chapitreId'),
      ),
    ).thenAnswer(
      (_) async => Right(entryOf(coursId: 'c', date: date, slot: 's1')),
    );
  });

  Future<JournalEntryCubit> openOn(JournalLine line) async {
    final cubit = JournalEntryCubit(seed: seed, chapter: chapter, save: save);
    await cubit.open(line, date: date, slotOrder: const {});
    return cubit;
  }

  test('séance vierge : le chapitre en cours et la dernière C.B', () async {
    final cubit = await openOn(lineWith());

    expect(cubit.state.status, JournalEntryStatus.editing);
    expect(cubit.state.chapitreId, 'ch-2');
    expect(cubit.state.fields.cb, 'Résoudre');
    expect(cubit.state.fields.objectif, 'Calculer une aire');
    expect(cubit.state.fields.contenu, 'Aires');
  });

  test('séance saisie : sa saisie, son chapitre, rien de recopié', () async {
    final cubit = await openOn(
      lineWith(
        fields: const JournalFields(objectif: 'Mien', contenu: 'Mien'),
        chapitreId: 'ch-1',
      ),
    );

    expect(cubit.state.chapitreId, 'ch-1');
    expect(cubit.state.fields.objectif, 'Mien');
    verifyNever(() => chapter(any()));
  });

  test('un chapitre disparu du programme se lit hors programme', () async {
    final cubit = await openOn(
      lineWith(
        fields: const JournalFields(objectif: 'O', contenu: 'C'),
        chapitreId: 'gone',
      ),
    );

    expect(cubit.state.chapitreId, isNull);
  });

  test('saisie intacte : changer de chapitre le recopie', () async {
    final cubit = await openOn(lineWith());

    cubit.selectChapter('ch-1');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.fields.contenu, 'Nombres');
    expect(cubit.state.canApplyChapter, isFalse);
  });

  test(
    'saisie commencée : rien n\'est écrasé, « Reprendre » le propose',
    () async {
      final cubit = await openOn(lineWith());
      cubit.updateField(JournalField.contenu, 'Ma séance');

      cubit.selectChapter('ch-1');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.fields.contenu, 'Ma séance');
      expect(cubit.state.canApplyChapter, isTrue);

      await cubit.applyChapter();
      expect(cubit.state.fields.contenu, 'Nombres');
      expect(cubit.state.canApplyChapter, isFalse);
    },
  );

  test(
    'enregistrer sans objectif ni contenu : erreurs, rien n\'est écrit',
    () async {
      final cubit = await openOn(lineWith());
      cubit.updateField(JournalField.objectif, ' ');

      await cubit.save();

      expect(cubit.state.showErrors, isTrue);
      expect(cubit.state.refusals, 1);
      verifyNever(
        () => save(
          any(),
          fields: any(named: 'fields'),
          chapitreId: any(named: 'chapitreId'),
        ),
      );
    },
  );

  test('enregistrer : la saisie et le chapitre partent', () async {
    final cubit = await openOn(lineWith());

    await cubit.save();

    expect(cubit.state.status, JournalEntryStatus.saved);
    final captured = verify(
      () => save(
        captureAny(),
        fields: captureAny(named: 'fields'),
        chapitreId: captureAny(named: 'chapitreId'),
      ),
    ).captured;
    expect((captured[0] as JournalSeanceKey).timeSlotId, 's1');
    expect((captured[1] as JournalFields).contenu, 'Aires');
    expect(captured[2], 'ch-2');
  });

  test('vider : champs vides, sans chapitre, sans validation', () async {
    final cubit = await openOn(
      lineWith(
        fields: const JournalFields(objectif: 'O', contenu: 'C'),
        chapitreId: 'ch-1',
      ),
    );

    await cubit.clear();

    expect(cubit.state.status, JournalEntryStatus.cleared);
    verify(
      () => save(any(), fields: JournalFields.empty, chapitreId: null),
    ).called(1);
  });

  test(
    'écriture locale en échec : la modale reste ouverte, saisie gardée',
    () async {
      when(
        () => save(
          any(),
          fields: any(named: 'fields'),
          chapitreId: any(named: 'chapitreId'),
        ),
      ).thenAnswer((_) async => const Left(StorageFailure('ko')));
      final cubit = await openOn(lineWith());

      await cubit.save();

      expect(cubit.state.status, JournalEntryStatus.editing);
      expect(cubit.state.failure, isA<StorageFailure>());
      expect(cubit.state.fields.contenu, 'Aires');
    },
  );
}
