import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  late List<ParentSearchCriteria> emitted;

  Future<void> pumpForm(WidgetTester tester, {double width = 520}) async {
    emitted = [];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: width,
              child: ParentSearchForm(onSearch: emitted.add),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// `EteeloTextInput` habille un `TextField` réel : la saisie vise ce
  /// dernier, pas le wrapper stylé.
  Finder champ(String label) => find.descendant(
    of: find.byWidgetPredicate((w) => w is EteeloTextInput && w.label == label),
    matching: find.byType(TextField),
  );

  Future<void> basculer(WidgetTester tester, String onglet) async {
    await tester.tap(find.text(onglet));
    await tester.pumpAndSettle();
  }

  testWidgets('ouvre sur la recherche par numéro', (tester) async {
    await pumpForm(tester);

    expect(find.text('+243'), findsOneWidget);
    expect(find.text('Nom'), findsNothing);
  });

  testWidgets('un seul chiffre arme la recherche par numéro', (tester) async {
    await pumpForm(tester);

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
      reason: 'un champ vide ne doit pas armer la recherche',
    );

    await tester.enterText(find.byType(TextField).first, '8169');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();

    expect(emitted, hasLength(1));
    // La bribe part en E.164, comme le reste de l'application.
    expect(emitted.single.phoneNumber, '+2438169');
    expect(emitted.single.lastName, isNull);
  });

  testWidgets('l\'identité exige nom ET prénom, le postnom reste facultatif', (
    tester,
  ) async {
    await pumpForm(tester);
    await basculer(tester, 'Par identité');

    await tester.enterText(champ('Nom'), 'Moke');
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
      reason: 'un nom seul remonterait la moitié du carnet',
    );

    await tester.enterText(champ('Prénom'), 'Sarah');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();

    expect(emitted, hasLength(1));
    expect(emitted.single.lastName, 'Moke');
    expect(emitted.single.firstName, 'Sarah');
    expect(emitted.single.surname, isNull);
    expect(
      emitted.single.phoneNumber,
      isNull,
      reason: 'les critères de l\'autre mode ne partent jamais dans la requête',
    );
  });

  testWidgets('la saisie de l\'autre mode est conservée à la bascule', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField).first, '816939060');
    await tester.pumpAndSettle();

    await basculer(tester, 'Par identité');
    await basculer(tester, 'Par numéro');

    expect(find.text('816939060'), findsWidgets);
  });
}
