import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_actions_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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

CalendarActionsRow _row({
  required bool compact,
  bool canWrite = true,
  VoidCallback? print,
  VoidCallback? duplicate,
}) => CalendarActionsRow(
  phase: CalendarPhase.inForce,
  canWrite: canWrite,
  compact: compact,
  actions: CalendarActions(
    openElement: (_) {},
    addOn: (_) {},
    back: () {},
    print: print,
    duplicate: duplicate,
  ),
);

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('téléphone : l’aide dit « Touchez », jamais « Cliquez »', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(_app(_row(compact: true)));
    expect(find.textContaining('Touchez un jour'), findsOneWidget);
    expect(find.textContaining('Cliquez'), findsNothing);
  });

  testWidgets('tablette (doigt) : « Touchez un jour libre »', (tester) async {
    await tester.pumpWidget(_app(_row(compact: false)));
    expect(find.textContaining('Touchez un jour libre'), findsOneWidget);
  });

  testWidgets('poste (souris) : « Cliquez »', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.pumpWidget(_app(_row(compact: false, canWrite: false)));
    expect(find.textContaining('Cliquez un élément'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('téléphone : imprimer et dupliquer passent par « ⋯ », '
      'Ajouter part dans le bouton flottant', (tester) async {
    phone(tester);
    var printed = 0;
    await tester.pumpWidget(
      _app(_row(compact: true, print: () => printed++, duplicate: () {})),
    );
    expect(find.text('Imprimer'), findsNothing);
    expect(find.text('Ajouter'), findsNothing);
    await tester.tap(find.byTooltip("Plus d'actions"));
    await tester.pumpAndSettle();
    expect(find.text('Dupliquer'), findsOneWidget);
    await tester.tap(find.text('Imprimer'));
    await tester.pumpAndSettle();
    expect(printed, 1);
  });

  testWidgets('large : les actions restent des boutons', (tester) async {
    await tester.pumpWidget(_app(_row(compact: false, print: () {})));
    expect(find.text('Imprimer'), findsOneWidget);
    expect(find.text('Ajouter'), findsOneWidget);
  });
}
