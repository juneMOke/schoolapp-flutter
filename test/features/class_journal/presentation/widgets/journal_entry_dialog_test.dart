import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/journal_entry_use_cases.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/entry/journal_entry_dialog.dart';

import '../../../course_programme/presentation/programme_test_host.dart';
import '../../journal_fixtures.dart';

class _MockSeed extends Mock implements LoadJournalFormSeedUseCase {}

class _MockChapter extends Mock implements LoadJournalChapterUseCase {}

class _MockSave extends Mock implements SaveJournalEntryUseCase {}

void main() {
  late _MockSave save;
  late JournalEntryCubit cubit;
  final date = DateTime(2026, 10, 14);

  JournalLine lineWith({JournalFields? fields}) => JournalLine(
    timeSlotId: 's1',
    slot: kSchoolSlots.first,
    coursId: 'c',
    subjectLabel: 'Mathématiques',
    classroomLabel: '7e A',
    status: JournalStatus.toPrepare,
    entry: fields == null
        ? null
        : entryOf(coursId: 'c', date: date, slot: 's1', fields: fields),
  );

  setUpAll(() {
    registerFallbackValue(
      JournalSeanceKey(coursId: 'c', date: DateTime(2000), timeSlotId: 's'),
    );
    registerFallbackValue(JournalFields.empty);
  });

  setUp(() {
    final seed = _MockSeed();
    save = _MockSave();
    when(
      () => seed('c', slotOrder: any(named: 'slotOrder')),
    ).thenAnswer((_) async => const JournalFormSeed(chapters: [], lastCb: ''));
    when(
      () => save(
        any(),
        fields: any(named: 'fields'),
        chapitreId: any(named: 'chapitreId'),
      ),
    ).thenAnswer(
      (_) async => Right(entryOf(coursId: 'c', date: date, slot: 's1')),
    );
    cubit = JournalEntryCubit(seed: seed, chapter: _MockChapter(), save: save);
  });
  tearDown(() => cubit.close());

  Future<void> pump(
    WidgetTester tester,
    JournalLine line, {
    Size size = const Size(1280, 900),
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
    await cubit.open(line, date: date, slotOrder: const {});
    await tester.pumpWidget(
      programmeHost(
        BlocProvider<JournalEntryCubit>.value(
          value: cubit,
          child: JournalEntryDialog(line: line, date: date),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('séance vierge : en-tête, hors programme, pas de « Vider »', (
    tester,
  ) async {
    await pump(tester, lineWith());

    expect(find.text('Mathématiques — 7e A'), findsOneWidget);
    expect(find.textContaining('1RE HEURE'), findsOneWidget);
    expect(
      find.text(
        'Ce cours n\'a pas encore de chapitre : créez-le dans Cours ▸ Mes cours.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vider la séance'), findsNothing);
  });

  testWidgets('hors programme s\'affiche tel quel, pas l\'invite du choix', (
    tester,
  ) async {
    await pump(tester, lineWith());

    expect(find.text('— Hors programme / séance libre'), findsOneWidget);
  });

  testWidgets('enregistrer sans objectif ni contenu : les deux messages', (
    tester,
  ) async {
    await pump(tester, lineWith());

    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(find.text('Indiquez l\'objectif de la séance.'), findsOneWidget);
    expect(find.text('Indiquez le contenu de la séance.'), findsOneWidget);
  });

  testWidgets('séance saisie : ses valeurs, et « Vider la séance »', (
    tester,
  ) async {
    await pump(
      tester,
      lineWith(
        fields: const JournalFields(objectif: 'Calculer', contenu: 'Aires'),
      ),
    );

    expect(find.text('Calculer'), findsOneWidget);
    await tester.tap(find.text('Vider la séance'));
    await tester.pump();

    verify(
      () => save(any(), fields: JournalFields.empty, chapitreId: null),
    ).called(1);
  });

  testWidgets('paysage, clavier ouvert : rien ne déborde', (tester) async {
    await pump(
      tester,
      lineWith(
        fields: const JournalFields(objectif: 'O', contenu: 'C'),
      ),
      size: const Size(1280, 800),
      keyboard: 380,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Enregistrer'), findsOneWidget);
  });
}
