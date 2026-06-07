import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/facturation_results_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, {List<String> criteria = const []}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FacturationResultsEmptyState(criteria: criteria),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'réutilise EteeloEmptyResult avec le message facturation (sans critère)',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(EteeloEmptyResult), findsOneWidget);
      expect(find.text('Aucun élève trouvé'), findsOneWidget);
    },
  );

  testWidgets('affiche les puces de critères de recherche', (tester) async {
    await _pump(tester, criteria: const ['Nom: Kabongo', 'Prénom: Daniel']);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloEmptyResult), findsOneWidget);
    expect(find.text('Nom: Kabongo'), findsOneWidget);
    expect(find.text('Prénom: Daniel'), findsOneWidget);
  });
}
