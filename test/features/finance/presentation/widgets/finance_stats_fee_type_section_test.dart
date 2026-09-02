import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_fee_type_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mapping fait déjà retomber un libellé vide sur le code : l'entité qui
/// arrive au widget en porte donc toujours un.
FeeTypeItem _item({
  required String code,
  String? label,
  int collected = 18000,
  int expected = 30000,
  int outstanding = 12000,
  int rate = 60,
}) {
  return FeeTypeItem(
    code: code,
    label: label ?? code,
    collected: collected,
    expected: expected,
    outstanding: outstanding,
    collectionRate: rate,
  );
}

Future<void> _pumpInPageBackground(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche le libellé du SERVEUR, pas la table locale', (
    tester,
  ) async {
    await _pumpInPageBackground(
      tester,
      FinanceStatsFeeTypeSection(
        items: [_item(code: 'TUITION', label: 'Minerval')],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Minerval'), findsOneWidget);
    // Ce test épinglait l'inverse : le libellé de la table locale des vingt-
    // trois traductions. Le serveur envoie désormais le sien, et deux tables
    // divergent à la première nature de frais ajoutée.
    expect(find.text('Frais de scolarité'), findsNothing);
    expect(find.text('TUITION'), findsNothing);
  });

  testWidgets('un poste sans libellé garde son code, pas un générique', (
    tester,
  ) async {
    await _pumpInPageBackground(
      tester,
      FinanceStatsFeeTypeSection(items: [_item(code: 'MYSTERY_FEE')]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MYSTERY_FEE'), findsOneWidget);
    expect(find.text('Frais scolaire'), findsNothing);
  });

  testWidgets('le reste dû est affiché à côté de l’encaissé et de l’attendu', (
    tester,
  ) async {
    await _pumpInPageBackground(
      tester,
      FinanceStatsFeeTypeSection(
        items: [
          _item(
            code: 'TUITION',
            label: 'Minerval',
            collected: 145000,
            expected: 120000,
            outstanding: 40000,
            rate: 66,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Le cas qui rendait la carte incohérente : l'encaissé DÉPASSE l'attendu —
    // un arriéré d'un autre exercice qui se solde — pendant que la barre reste
    // aux deux tiers. Sans le reste dû, rien n'explique l'écart.
    expect(find.textContaining('Encaissé'), findsOneWidget);
    expect(find.textContaining('Attendu'), findsOneWidget);
    expect(find.textContaining('Reste dû'), findsOneWidget);
    expect(find.text('Taux : 66%'), findsOneWidget);
  });

  testWidgets('rien d’attendu : « sans objet », jamais un taux', (
    tester,
  ) async {
    await _pumpInPageBackground(
      tester,
      FinanceStatsFeeTypeSection(
        items: [
          _item(
            code: 'TRANSPORT',
            label: 'Transport scolaire',
            collected: 0,
            expected: 0,
            outstanding: 0,
            // Ce que le serveur envoie quand `expected` vaut 0.
            rate: 100,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Taux : sans objet'), findsOneWidget);
    expect(find.text('Taux : 100%'), findsNothing);
  });
}
