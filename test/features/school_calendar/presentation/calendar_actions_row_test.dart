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
  CalendarPhase phase = CalendarPhase.inForce,
  VoidCallback? print,
  VoidCallback? duplicate,
  VoidCallback? publish,
}) => CalendarActionsRow(
  phase: phase,
  canWrite: canWrite,
  compact: compact,
  actions: CalendarActions(
    openElement: (_) {},
    addOn: (_) {},
    back: () {},
    print: print,
    duplicate: duplicate,
    publish: publish,
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

  testWidgets('téléphone : l’aide au-dessus, Imprimer et Dupliquer en '
      'icônes de 48 dp, Ajouter sur la ligne (pas de « ⋯ »)', (tester) async {
    phone(tester);
    var printed = 0;
    await tester.pumpWidget(
      _app(_row(compact: true, print: () => printed++, duplicate: () {})),
    );
    expect(find.text('Imprimer'), findsNothing);
    expect(find.byTooltip("Plus d'actions"), findsNothing);
    expect(find.text('Ajouter'), findsOneWidget);
    final help = tester.getCenter(find.textContaining('Touchez un jour'));
    final add = tester.getCenter(find.text('Ajouter'));
    expect(help.dy, lessThan(add.dy));
    final icon = find.byTooltip('Imprimer');
    expect(tester.getSize(icon).height, greaterThanOrEqualTo(48));
    await tester.tap(icon);
    expect(printed, 1);
    expect(find.byTooltip("Dupliquer pour l'année suivante"), findsOneWidget);
  });

  testWidgets('téléphone, brouillon : Ajouter et Publier se partagent la '
      'ligne', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      _app(
        _row(
          compact: true,
          phase: CalendarPhase.draft,
          duplicate: () {},
          publish: () {},
        ),
      ),
    );
    final add = tester.getCenter(find.text('Ajouter'));
    final publish = tester.getCenter(find.text('Publier'));
    expect((add.dy - publish.dy).abs(), lessThan(1));
    expect(publish.dx, greaterThan(add.dx));
  });

  testWidgets('large : les actions restent des boutons', (tester) async {
    await tester.pumpWidget(_app(_row(compact: false, print: () {})));
    expect(find.text('Imprimer'), findsOneWidget);
    expect(find.text('Ajouter'), findsOneWidget);
  });

  testWidgets('tablette en deçà de 976 dp : pas de « ⋯ », les gestes en '
      'clair', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(_row(compact: false, print: () {}, duplicate: () {})),
    );
    expect(find.text('Imprimer'), findsOneWidget);
    expect(find.text('Dupliquer'), findsOneWidget);
    expect(find.byTooltip("Plus d'actions"), findsNothing);
  });
}
