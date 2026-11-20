import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_actions_row.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/element_detail_sheet.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/event_form_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'fake_calendar_repository.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

final _proclamation = CalendarElement(
  id: 'proclamation-p1',
  source: CalendarSource.national,
  nature: CalendarNature.schoolLife,
  title: 'Proclamation du 1er trimestre',
  startDate: d(2026, 6, 6),
  endDate: d(2026, 6, 6),
  scope: const RhythmScope(PeriodRhythm.trimester),
  replaceable: true,
);

CalendarElement _schoolCopy({String? replaces = 'proclamation-p1'}) =>
    CalendarElement(
      id: 'r1',
      source: CalendarSource.school,
      nature: CalendarNature.schoolLife,
      title: 'Proclamation du 1er trimestre',
      startDate: d(2026, 6, 9),
      endDate: d(2026, 6, 9),
      scope: const RhythmScope(PeriodRhythm.trimester),
      replaces: replaces,
    );

Future<ElementDetailChoice?> _openSheet(
  WidgetTester tester,
  CalendarElement element, {
  bool canEdit = true,
  CalendarElement? replaced,
}) async {
  ElementDetailChoice? choice;
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => choice = await showDialog(
            context: context,
            builder: (_) => Dialog(
              child: ElementDetailSheet(
                element: element,
                scopes: const CalendarScopeOptions(),
                canEdit: canEdit,
                replaced: replaced,
              ),
            ),
          ),
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return choice;
}

void main() {
  testWidgets('un élément national remplaçable propose « Remplacer… »', (
    tester,
  ) async {
    await _openSheet(tester, _proclamation);
    expect(find.text('Remplacer…'), findsOneWidget);
    expect(
      find.textContaining('votre école peut le remplacer'),
      findsOneWidget,
    );
    expect(find.text('Modifier'), findsNothing);
  });

  testWidgets('verrouillé ou sans droit : rien à remplacer', (tester) async {
    await _openSheet(
      tester,
      CalendarElement(
        id: 'ferie',
        source: CalendarSource.national,
        nature: CalendarNature.publicHoliday,
        title: 'Noël',
        startDate: d(2026, 12, 25),
        endDate: d(2026, 12, 25),
      ),
    );
    expect(find.text('Remplacer…'), findsNothing);
    await _openSheet(tester, _proclamation, canEdit: false);
    expect(find.text('Remplacer…'), findsNothing);
  });

  testWidgets('un remplacement nomme l’élément national et le rétablit', (
    tester,
  ) async {
    await _openSheet(tester, _schoolCopy(), replaced: _proclamation);
    expect(find.text("Remplace l'élément national"), findsOneWidget);
    expect(find.text('Rétablir la date nationale'), findsOneWidget);
    expect(find.text('Supprimer'), findsNothing);
  });

  testWidgets(
    'le formulaire de remplacement fige nature et portée, et garde la cible',
    (tester) async {
      CalendarElement? saved;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await EventFormDialog.show(
                context,
                EventFormDialog(
                  newId: 'new',
                  replacing: _proclamation,
                  natures: const {CalendarNature.schoolLife},
                  scopes: const CalendarScopeOptions(),
                  yearStart: d(2025, 9, 1),
                  yearEnd: d(2026, 7, 3),
                  nationalElements: [_proclamation],
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Remplacer un élément national'), findsOneWidget);
      expect(find.textContaining('vaut pour votre école'), findsOneWidget);
      // Le remplacé ne s'avertit pas lui-même.
      expect(find.textContaining('chevauche'), findsNothing);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Remplacer'));
      await tester.pumpAndSettle();
      expect(saved?.id, 'new');
      expect(saved?.replaces, 'proclamation-p1');
      expect(saved?.nature, CalendarNature.schoolLife);
      expect(saved?.scope, const RhythmScope(PeriodRhythm.trimester));
      expect(saved?.source, CalendarSource.school);
    },
  );

  test(
    'le calendrier masque l’élément remplacé, pas s’il est refusé',
    () async {
      final repo = FakeCalendarRepository()..extraItems = [_proclamation];
      repo.stored = [
        SchoolEventRecord(
          element: _schoolCopy(),
          calendarId: 'cal-2025-2026',
          clientUpdatedAtMs: 1,
        ),
      ];
      final c = SchoolCalendarCubit(repo, schoolToday: () => d(2026, 6, 10));
      await c.load();
      await c.open('2025-2026');
      var ids = [for (final e in c.state.allElements) e.id];
      expect(ids, contains('r1'));
      expect(ids, isNot(contains('proclamation-p1')));
      expect(c.state.nationalOf('proclamation-p1'), _proclamation);

      repo.stored = [
        SchoolEventRecord(
          element: _schoolCopy(),
          calendarId: 'cal-2025-2026',
          clientUpdatedAtMs: 1,
          syncState: RecordSyncState.failed,
        ),
      ];
      await c.close();
      final c2 = SchoolCalendarCubit(repo, schoolToday: () => d(2026, 6, 10));
      await c2.load();
      await c2.open('2025-2026');
      ids = [for (final e in c2.state.allElements) e.id];
      expect(ids, containsAll(['r1', 'proclamation-p1']));
      await c2.close();
    },
  );

  testWidgets('« Document du ministère » se montre quand le cadre en a un', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      _app(
        CalendarActionsRow(
          phase: CalendarPhase.inForce,
          canWrite: false,
          actions: CalendarActions(
            openElement: (_) {},
            addOn: (_) {},
            back: () {},
            officialDocument: () => opened++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Document du ministère'));
    expect(opened, 1);
  });

  test('le document se demande pour l’année ouverte', () async {
    final repo = FakeCalendarRepository()
      ..documentResult = Right(
        PrintableDocument(
          bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
          fileName: 'calendrier-scolaire-2025-2026.pdf',
        ),
      );
    final c = SchoolCalendarCubit(repo, schoolToday: () => d(2026, 6, 10));
    await c.load();
    await c.open('2025-2026');
    final result = await c.frameworkDocument();
    expect(result.isRight(), isTrue);
    expect(repo.documentYears, ['2025-2026']);
    await c.close();
  });
}
