import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/home/presentation/widget/top_bar_parts/top_bar_title.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  TopBarTitle title({required bool isCompact}) => TopBarTitle(
    moduleTitle: 'Inscriptions',
    title: 'Première inscription',
    isPreRegistrations: false,
    selectedSubMenuId: null,
    isCompact: isCompact,
  );

  testWidgets('Desktop : icône de tête affichée + titre', (tester) async {
    await tester.pumpWidget(harness(title(isCompact: false)));

    expect(find.byIcon(Icons.dashboard_customize_outlined), findsOneWidget);
    expect(find.text('Première inscription'), findsOneWidget);
  });

  testWidgets('Mobile (compact) : icône de tête masquée, titre conservé', (
    tester,
  ) async {
    await tester.pumpWidget(harness(title(isCompact: true)));

    expect(find.byIcon(Icons.dashboard_customize_outlined), findsNothing);
    expect(find.text('Première inscription'), findsOneWidget);
  });

  testWidgets('Accueil : icône de tête « home » (spec §09)', (tester) async {
    await tester.pumpWidget(
      harness(
        const TopBarTitle(
          moduleTitle: 'ETEELO CONNECT',
          title: 'Accueil',
          isPreRegistrations: false,
          selectedSubMenuId: MenuConstants.accueilId,
          isCompact: false,
        ),
      ),
    );

    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
  });
}
