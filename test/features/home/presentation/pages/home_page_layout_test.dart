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
}
