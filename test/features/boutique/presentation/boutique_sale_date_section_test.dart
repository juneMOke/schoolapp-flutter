import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_confirm_dialog.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_date_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _backdatedNote = 'Vente antidatée — la date figurera sur le ticket.';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

/// Le champ « Date de la vente » en tête du panier (BQ-19).
void main() {
  final today = DateTime(2026, 10, 21, 14, 30);

  Future<List<DateTime?>> pump(
    WidgetTester tester, {
    DateTime? saleDate,
    DateTime? yearStart,
  }) async {
    final emitted = <DateTime?>[];
    await tester.pumpWidget(
      _app(
        BoutiqueSaleDateSection(
          saleDate: saleDate,
          academicYearStart: yearStart ?? DateTime(2026, 9, 1),
          onChanged: emitted.add,
          now: () => today,
        ),
      ),
    );
    return emitted;
  }

  testWidgets('par défaut : aujourd\'hui, et aucune note', (tester) async {
    await pump(tester);

    expect(find.text('Date de la vente'), findsOneWidget);
    expect(find.text('21/10/2026'), findsOneWidget);
    expect(find.text(_backdatedNote), findsNothing);
  });

  testWidgets('antidatée : le jour choisi, et la note ambre', (tester) async {
    await pump(tester, saleDate: DateTime(2026, 10, 19));

    expect(find.text('19/10/2026'), findsOneWidget);
    expect(find.text(_backdatedNote), findsOneWidget);
  });

  testWidgets('reconfirmer aujourd\'hui rend `null`, jamais la date du jour', (
    tester,
  ) async {
    // Une date du jour figée deviendrait une vente antidatée passé minuit.
    final emitted = await pump(tester, saleDate: DateTime(2026, 10, 19));

    await tester.tap(find.text('19/10/2026'));
    await tester.pumpAndSettle();
    final dialog = find.byType(DatePickerDialog);
    expect(dialog, findsOneWidget);
    // Bornes du sélecteur : ouverture de l'année → aujourd'hui, jamais demain.
    final picker = tester.widget<DatePickerDialog>(dialog);
    expect(picker.firstDate, DateTime(2026, 9, 1));
    expect(picker.lastDate, DateTime(2026, 10, 21));

    Navigator.of(tester.element(dialog)).pop(DateTime(2026, 10, 21));
    await tester.pumpAndSettle();
    expect(emitted, [null]);
  });

  testWidgets('un jour passé choisi est rendu tel quel', (tester) async {
    final emitted = await pump(tester);

    await tester.tap(find.text('21/10/2026'));
    await tester.pumpAndSettle();
    Navigator.of(
      tester.element(find.byType(DatePickerDialog)),
    ).pop(DateTime(2026, 10, 2));
    await tester.pumpAndSettle();
    expect(emitted, [DateTime(2026, 10, 2)]);
  });

  group('borne basse', () {
    test('rentrée inconnue : un an en arrière', () {
      expect(
        BoutiqueSaleDateSection.firstSelectableDay(
          null,
          DateTime(2026, 10, 21),
        ),
        DateTime(2025, 10, 21),
      );
    });

    test('rentrée dans le futur : aujourd\'hui, sinon le sélecteur lève', () {
      expect(
        BoutiqueSaleDateSection.firstSelectableDay(
          DateTime(2027, 9, 1),
          DateTime(2026, 10, 21),
        ),
        DateTime(2026, 10, 21),
      );
    });
  });

  testWidgets('la confirmation nomme la date de la vente', (tester) async {
    const article = BoutiqueArticle(
      id: 'art-ecu',
      academicYearId: 'ay-1',
      code: 'ECUS',
      label: 'Écusson',
      family: ArticleFamily.uniforme,
      pricingMode: PricingMode.prixUnique,
      unitPriceInCents: 1000,
      currency: 'USD',
    );
    final cart = const BoutiqueCart(
      lines: [CartLine(key: 'k0', article: article)],
    ).withSaleDate(DateTime(2026, 10, 19));

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => BoutiqueConfirmDialog.show(
              context,
              cart: cart,
              payerIsNew: false,
              isOffline: false,
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Date'), findsOneWidget);
    expect(find.text('19/10/2026'), findsOneWidget);
  });
}
