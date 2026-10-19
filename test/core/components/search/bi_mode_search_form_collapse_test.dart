import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/search/bi_mode_search_form.dart';
import 'package:school_app_flutter/core/components/search/search_collapsed_summary.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sur un téléphone, la recherche lancée se replie en une ligne : dépliée,
/// la carte occupait ~500 dp et les résultats commençaient hors de l'écran.
void main() {
  Future<List<SearchRequest>> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final requests = <SearchRequest>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BiModeSearchForm(
              options: const [],
              isLoading: false,
              onSearch: requests.add,
              labels: const BiModeSearchLabels(
                title: 'Rechercher',
                helpBanner: 'Par classe ou par nom',
                cycleLabel: 'Cycle',
                levelLabel: 'Niveau',
                levelPlaceholder: 'Choisir',
              ),
            ),
          ),
        ),
      ),
    );
    return requests;
  }

  Future<void> searchByName(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pump();
    await tester.tap(find.text('Rechercher').last);
    await tester.pumpAndSettle();
  }

  testWidgets('téléphone : repliée en résumé, puis rouverte', (tester) async {
    final requests = await pump(tester, const Size(360, 740));
    await searchByName(tester, 'Kabeya');

    expect(requests, hasLength(1));
    expect(find.byType(SearchCollapsedSummary), findsOneWidget);
    expect(find.text('Kabeya'), findsOneWidget);
    expect(find.byType(SearchModeSwitch), findsNothing);

    await tester.tap(find.byTooltip('Modifier la recherche'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchModeSwitch), findsOneWidget);
    // La saisie est restée.
    expect(find.widgetWithText(TextField, 'Kabeya'), findsOneWidget);
  });

  testWidgets('grand écran : la carte reste dépliée', (tester) async {
    await pump(tester, const Size(1280, 800));
    await searchByName(tester, 'Kabeya');

    expect(find.byType(SearchCollapsedSummary), findsNothing);
    expect(find.byType(SearchModeSwitch), findsOneWidget);
  });
}
