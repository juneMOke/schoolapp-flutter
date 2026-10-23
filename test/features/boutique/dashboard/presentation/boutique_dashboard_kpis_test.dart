import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_kpis.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../dashboard_fixtures.dart';

/// Les pavés de chiffres clés — le modèle des caisses Finances.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool comparable,
    List<String> currencies = const ['USD'],
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: SingleChildScrollView(
            child: BoutiqueDashboardKpis(
              stats: statsOf(currencies: currencies),
              deltaComparable: comparable,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('chaque chiffre dit son évolution, signée', (tester) async {
    await pump(tester, comparable: true);
    // Ventes 61 contre 55.
    expect(find.text('+11 % vs période précédente'), findsOneWidget);
    // Articles 97 contre 88.
    expect(find.text('+10 % vs période précédente'), findsOneWidget);
    // Recettes 1 284 $ contre 1 102 $.
    expect(find.text('+17 % vs période précédente'), findsOneWidget);
  });

  testWidgets('avant la rentrée : aucune flèche, et chaque pavé le dit', (
    tester,
  ) async {
    await pump(tester, comparable: false);
    expect(find.byIcon(Icons.trending_up_rounded), findsNothing);
    expect(
      find.text('Pas de période comparable avant la rentrée'),
      findsNWidgets(4),
    );
  });

  testWidgets('deux devises : aucun pourcentage de montant', (tester) async {
    await pump(tester, comparable: true, currencies: const ['USD', 'CDF']);
    expect(find.text('+17 % vs période précédente'), findsNothing);
    // Les compteurs, eux, se comparent toujours.
    expect(find.text('+11 % vs période précédente'), findsOneWidget);
  });
}
