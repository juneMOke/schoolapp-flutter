import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_reason_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<String?> open(
    WidgetTester tester, {
    required bool isRequired,
    String? typed,
  }) async {
    String? result = 'non rendu';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await EteeloReasonDialog.show(
                context,
                EteeloReasonDialog(
                  title: 'Refuser',
                  confirmLabel: 'Confirmer',
                  cancelLabel: 'Annuler',
                  fieldLabel: 'Motif',
                  requiredError: 'Motif obligatoire',
                  helper: 'Visible par le parent',
                  isRequired: isRequired,
                  maxLength: 5,
                ),
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    if (typed != null) await tester.enterText(find.byType(TextField), typed);
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('obligatoire : vide, la modale reste et le dit', (tester) async {
    final result = await open(tester, isRequired: true);
    expect(result, 'non rendu');
    expect(find.text('Motif obligatoire'), findsOneWidget);
    expect(find.text('Visible par le parent'), findsOneWidget);
  });

  testWidgets('facultatif : vide, elle rend une chaîne vide', (tester) async {
    expect(await open(tester, isRequired: false), '');
  });

  // Un texte libre : la première lettre est capitalisée (règle n°11).
  testWidgets('la saisie est rognée et bornée', (tester) async {
    expect(await open(tester, isRequired: true, typed: '  abcdefgh'), 'Abc');
  });
}
