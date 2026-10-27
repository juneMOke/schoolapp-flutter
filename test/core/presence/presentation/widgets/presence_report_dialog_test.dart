import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la modale a rendu en se refermant.
class _Result {
  PresenceReportChoice? choice;
}

/// La modale de validation d'un registre : les non pointés sont nommés, et
/// les marquer présents est un choix, jamais un défaut.
void main() {
  Future<_Result> open(WidgetTester tester, List<String> names) async {
    final result = _Result();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result.choice = await showDialog<PresenceReportChoice>(
                    context: context,
                    builder: (_) => PresenceReportDialog(
                      eyebrow: 'Mardi 27 octobre 2026',
                      title: 'Rapport du jour',
                      present: 10,
                      late: 1,
                      absent: 2,
                      unmarked: names.length,
                      unmarkedNames: names,
                      unjustified: 0,
                      unmarkedLabel: 'Les marquer présents',
                      lockMessage: 'La validation verrouille la journée.',
                      confirmLabel: 'Valider',
                    ),
                  ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('les cinq premiers noms, puis « et N autres »', (tester) async {
    await open(tester, [
      'Mbala',
      'Ilunga',
      'Zola',
      'Kasongo',
      'Lukusa',
      'Tshibola',
    ]);

    expect(
      find.text(
        'Pas encore pointés : Mbala, Ilunga, Zola, Kasongo, Lukusa et 1 autre.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('cinq noms tiennent sans résumé', (tester) async {
    await open(tester, ['Mbala', 'Ilunga', 'Zola', 'Kasongo', 'Lukusa']);

    expect(
      find.text('Pas encore pointés : Mbala, Ilunga, Zola, Kasongo, Lukusa.'),
      findsOneWidget,
    );
  });

  testWidgets('la case « marquer présents » est décochée par défaut', (
    tester,
  ) async {
    final result = await open(tester, ['Zola']);

    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isFalse);

    await tester.tap(find.text('Valider').last);
    await tester.pumpAndSettle();
    expect(result.choice?.markRemaining, isFalse);
    expect(result.choice?.reviewUnmarked, isFalse);
  });

  testWidgets('« Voir la liste » referme sans valider', (tester) async {
    final result = await open(tester, ['Zola']);
    expect(find.text('Pas encore pointé : Zola.'), findsOneWidget);

    await tester.tap(find.text('Voir la liste'));
    await tester.pumpAndSettle();

    expect(result.choice?.reviewUnmarked, isTrue);
    expect(result.choice?.markRemaining, isFalse);
  });
}
