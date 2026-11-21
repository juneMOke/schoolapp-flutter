import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/calendar_online_dialogs.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/element_detail_parts.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/element_detail_sheet.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/event_form_dialog.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/publish_calendar_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

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

CalendarElement _el({
  CalendarSource source = CalendarSource.school,
  bool toVerify = false,
  DateTime? start,
  DateTime? end,
}) => CalendarElement(
  id: 'e1',
  source: source,
  nature: CalendarNature.exam,
  title: 'Examens du 2e semestre',
  startDate: start ?? d(2026, 6, 15),
  endDate: end ?? d(2026, 6, 26),
  toVerify: toVerify,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(child));
  await tester.pumpAndSettle();
}

void main() {
  final l10n = AppLocalizationsFr();

  test('« En cours », « Terminé », « Demain », « Dans n jours »', () {
    final e = _el();
    expect(ElementDateCard.when(l10n, e, d(2026, 6, 10)), 'Dans 5 jours');
    expect(ElementDateCard.when(l10n, e, d(2026, 6, 14)), 'Demain');
    expect(ElementDateCard.when(l10n, e, d(2026, 6, 20)), 'En cours');
    expect(ElementDateCard.when(l10n, e, d(2026, 6, 27)), 'Terminé');
  });

  testWidgets('O1 : dates début → fin, durée, et gestes selon la hiérarchie', (
    tester,
  ) async {
    await _pump(
      tester,
      ElementDetailSheet(
        element: _el(toVerify: true),
        scopes: const CalendarScopeOptions(),
        canEdit: true,
        today: d(2026, 6, 10),
      ),
    );
    expect(find.text('EXAMENS'), findsOneWidget);
    expect(find.text('Dans 5 jours'), findsOneWidget);
    expect(find.text('À vérifier'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Supprimer'), findsOneWidget);
    expect(find.widgetWithText(EteeloButton, 'Modifier'), findsOneWidget);
    expect(find.widgetWithText(EteeloButton, 'Date vérifiée'), findsOneWidget);
  });

  testWidgets('O2 : libellé Nature, première nature permise, durée', (
    tester,
  ) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => EventFormDialog.show(
            context,
            EventFormDialog(
              newId: 'n',
              yearLabel: '2025-2026',
              natures: const {
                CalendarNature.assessment,
                CalendarNature.schoolLife,
              },
              scopes: const CalendarScopeOptions(),
              yearStart: d(2025, 9, 1),
              yearEnd: d(2026, 7, 3),
              nationalElements: const [],
              initialDay: d(2026, 6, 1),
            ),
          ),
          child: const Text('ouvrir'),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('CALENDRIER 2025-2026'), findsOneWidget);
    expect(find.text('Nature'), findsOneWidget);
    expect(find.text('Interrogations de la P2'), findsOneWidget);
    expect(find.textContaining('1 jour · '), findsOneWidget);
  });

  testWidgets('O3 : sans case cochée, « Dupliquer » est inactif', (
    tester,
  ) async {
    await _pump(
      tester,
      const DuplicateCalendarDialog(
        sourceYear: '2025-2026',
        targetYear: '2026-2027',
        eventCount: 3,
        windowCount: 2,
        targetFramework: FrameworkState.integrated,
      ),
    );
    EteeloButton dup() => tester.widget<EteeloButton>(
      find.widgetWithText(EteeloButton, 'Dupliquer'),
    );
    expect(dup().onPressed, isNotNull);
    expect(find.textContaining('publiée par ETEELO'), findsOneWidget);
    await tester.tap(find.text("Événements de l'école"));
    await tester.tap(find.text("Fenêtres d'interrogations"));
    await tester.pumpAndSettle();
    expect(dup().onPressed, isNull);
  });

  testWidgets('O5 : bloquée sans cadre, avec le relais de l’année', (
    tester,
  ) async {
    await _pump(
      tester,
      const PublishCalendarDialog(
        year: '2026-2027',
        total: 12,
        schoolCount: 4,
        toVerify: 0,
        hasFramework: false,
        online: true,
        pending: false,
        relay: (current: '2025-2026', end: '3 juil. 2026', start: '31 août'),
      ),
    );
    expect(find.textContaining('sans cadre national'), findsOneWidget);
    expect(find.textContaining('2025-2026 reste en vigueur'), findsOneWidget);
    final publish = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Publier'),
    );
    expect(publish.onPressed, isNull);
  });
}
