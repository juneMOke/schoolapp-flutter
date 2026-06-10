import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/home/presentation/pages/home_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHarness() {
    return const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomePage(),
    );
  }

  testWidgets('HomePage renders desktop structure above mobile breakpoint', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    expect(find.byType(Row), findsWidgets);
    expect(find.byType(Drawer), findsNothing);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byTooltip('Déconnexion'), findsOneWidget);
    expect(find.byTooltip('Replier le menu'), findsOneWidget);
    // Pas de hamburger en bureau (sidebar ancrée).
    expect(find.byTooltip('Ouvrir le menu'), findsNothing);
  });

  testWidgets('HomePage renders mobile scaffold with drawer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final scaffolds = tester
        .widgetList<Scaffold>(find.byType(Scaffold))
        .toList();
    final hasDrawer = scaffolds.any((scaffold) => scaffold.drawer != null);
    expect(hasDrawer, isTrue);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.byTooltip('Déconnexion'), findsNothing);
    // Hamburger présent en compact, avec son tooltip i18n dédié.
    expect(find.byTooltip('Ouvrir le menu'), findsOneWidget);
  });

  testWidgets('HomePage compact : le hamburger ouvre le tiroir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 740));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // La page d'accueil monte son propre Scaffold (AppPageBackground) dans le
    // corps : on cible explicitement la coquille compacte qui porte le tiroir,
    // et non « le dernier » Scaffold de l'arbre.
    final drawerScaffold = tester
        .widgetList<Scaffold>(find.byType(Scaffold))
        .firstWhere((scaffold) => scaffold.drawer != null);
    final scaffoldState = tester.state<ScaffoldState>(
      find.byWidget(drawerScaffold),
    );
    expect(scaffoldState.isDrawerOpen, isFalse);

    await tester.tap(find.byTooltip('Ouvrir le menu'));
    await tester.pumpAndSettle();

    expect(scaffoldState.isDrawerOpen, isTrue);
  });

  testWidgets('HomePage keeps compact drawer below 1024 breakpoint', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 740));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final scaffolds = tester
        .widgetList<Scaffold>(find.byType(Scaffold))
        .toList();
    final hasDrawer = scaffolds.any((scaffold) => scaffold.drawer != null);

    expect(hasDrawer, isTrue);
    expect(find.byTooltip('Déconnexion'), findsNothing);
  });

  testWidgets(
    'HomePage compact : taper l\'entrée « Accueil » ferme le tiroir',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 740));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      final drawerScaffold = tester
          .widgetList<Scaffold>(find.byType(Scaffold))
          .firstWhere((scaffold) => scaffold.drawer != null);
      final scaffoldState = tester.state<ScaffoldState>(
        find.byWidget(drawerScaffold),
      );

      await tester.tap(find.byTooltip('Ouvrir le menu'));
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, isTrue);

      // Item feuille déjà actif : le tap déclenche tout de même maybePop().
      final accueilInDrawer = find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Accueil'),
      );
      expect(accueilInDrawer, findsOneWidget);
      await tester.tap(accueilInDrawer);
      await tester.pumpAndSettle();

      expect(scaffoldState.isDrawerOpen, isFalse);
    },
  );
}
