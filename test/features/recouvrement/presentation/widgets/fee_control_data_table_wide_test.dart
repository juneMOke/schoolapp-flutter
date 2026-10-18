import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_data_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'fee_control_data_table_test.dart' show row;

/// Au seuil de la disposition large, aucun montant n'est tronqué.
///
/// Le seuil se mesure sur le contenu, sous la barre latérale : un poste en
/// 1280 offre ~952 dp. Un montant coupé par l'ellipse est un chiffre faux —
/// c'est la seule chose qui justifie de replier les colonnes.
void main() {
  testWidgets('au seuil large, le plus grand montant tient entier', (
    tester,
  ) async {
    // 900 dp de contenu + 2 × 24 de marge d'`AppPageBackground`.
    tester.view.physicalSize = const Size(948, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const big = 125000000; // 1 250 000,00
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppPageBackground(
          child: FeeControlDataTable(
            rows: [row('s1', lastName: 'MOKE', expected: big, mirror: 1000)],
            totalCount: 1,
            rate: null,
            selected: const {},
            marked: const {},
            onViewRequested: (_) {},
            onRowTapped: (_) {},
            onSelectionToggled: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ATTENDU'), findsOneWidget, reason: 'disposition large');
    final amount = formatMonetaryAmountWithCurrency(
      amount: big / 100,
      currency: 'USD',
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text(amount));
    final style = paragraph.text.style!;
    // Les montants s'écrivent en `monospace` générique — Consolas, DejaVu
    // Sans Mono, Courier New selon le poste : 0,55 à 0,60 em par caractère.
    // La police de test, elle, dessine des carrés d'1 em et ne mesure rien de
    // réel ; on vérifie donc la place offerte contre une chasse prudente.
    const monoAdvance = 0.62;
    final needed =
        amount.length * (style.fontSize! * monoAdvance + style.letterSpacing!);
    expect(paragraph.size.width, greaterThanOrEqualTo(needed));
  });
}
