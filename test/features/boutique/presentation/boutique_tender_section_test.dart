import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_tender.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_tender_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Le client règle en… », au comptoir.
///
/// Ce que la section tient : **le cas courant ne coûte rien** (aucun taux ⇒
/// rien à l'écran), la question se pose **par devise du panier**, et le montant
/// posé ne change jamais ce qui entre dans le tiroir — il dit seulement ce qui
/// repart avec le client, ou ce qui manque encore.
final _usdVersCdf = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2800000000,
  effectiveFrom: DateTime.utc(2026, 1, 1),
);

const _polo = BoutiqueArticle(
  id: 'art-polo',
  academicYearId: 'ay-1',
  code: 'POLO',
  label: 'Polo',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 5000, // 50,00 $
  currency: 'USD',
);

const _manuel = BoutiqueArticle(
  id: 'art-manuel',
  academicYearId: 'ay-1',
  code: 'MANUEL',
  label: 'Manuel',
  family: ArticleFamily.fournitures,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 9000000, // 90 000 FC
  currency: 'CDF',
);

Future<void> _pump(
  WidgetTester tester, {
  required BoutiqueCart cart,
  List<ExchangeRate> rates = const [],
  void Function(String, String)? onCurrencyChanged,
  void Function(String, int?)? onTenderedChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: BoutiqueTenderSection(
            cart: cart,
            rates: rates,
            onCurrencyChanged: onCurrencyChanged,
            onTenderedChanged: onTenderedChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const cartUsd = BoutiqueCart(
    lines: [CartLine(key: 'k0', article: _polo)],
  );

  testWidgets('sans taux paramétré, la section n’existe pas', (tester) async {
    await _pump(tester, cart: cartUsd);

    expect(find.textContaining('règle'), findsNothing);
  });

  testWidgets('avec un taux, la question se pose sur le sous-total dû', (
    tester,
  ) async {
    await _pump(tester, cart: cartUsd, rates: [_usdVersCdf]);

    expect(find.textContaining('LE CLIENT RÈGLE'), findsNothing);
    expect(find.textContaining('règle'), findsOneWidget);
    // Le sous-total est nommé : sur deux devises, deux blocs identiques ne se
    // distingueraient pas autrement.
    expect(find.textContaining('50,00'), findsOneWidget);
  });

  testWidgets('choisir les francs ouvre le champ, rempli par la conversion', (
    tester,
  ) async {
    await _pump(
      tester,
      cart: const BoutiqueCart(
        lines: [CartLine(key: 'k0', article: _polo)],
        tenders: {'USD': CartTender(currency: 'CDF')},
      ),
      rates: [_usdVersCdf],
    );

    expect(find.text('Reçu au comptoir'), findsOneWidget);
    final champ = tester.widget<TextField>(find.byType(TextField));
    expect(champ.controller?.text, '140000');
  });

  testWidgets('poser plus que le dû : la monnaie à rendre se dit', (
    tester,
  ) async {
    await _pump(
      tester,
      cart: const BoutiqueCart(
        lines: [CartLine(key: 'k0', article: _polo)],
        tenders: {'USD': CartTender(currency: 'CDF', tenderedCents: 15000000)},
      ),
      rates: [_usdVersCdf],
    );

    expect(find.textContaining('Monnaie à rendre'), findsOneWidget);
    expect(find.textContaining('Il manque'), findsNothing);
  });

  testWidgets('poser moins que le dû : ce qui manque se dit', (tester) async {
    // Une vente est comptant intégral : un billet trop court ne fabrique pas
    // une vente à moitié payée, il se signale.
    await _pump(
      tester,
      cart: const BoutiqueCart(
        lines: [CartLine(key: 'k0', article: _polo)],
        tenders: {'USD': CartTender(currency: 'CDF', tenderedCents: 13900000)},
      ),
      rates: [_usdVersCdf],
    );

    expect(find.textContaining('Il manque'), findsOneWidget);
    expect(find.textContaining('Monnaie à rendre'), findsNothing);
  });

  testWidgets('un panier à deux devises pose la question deux fois', (
    tester,
  ) async {
    await _pump(
      tester,
      cart: const BoutiqueCart(
        lines: [
          CartLine(key: 'k0', article: _polo),
          CartLine(key: 'k1', article: _manuel),
        ],
      ),
      rates: [_usdVersCdf],
    );

    // Le franc n'a aucun taux sortant : sa part ne propose rien, et seule celle
    // en dollars pose la question.
    expect(find.textContaining('règle'), findsOneWidget);
  });

  testWidgets('changer de devise remonte le pivot, pas seulement le choix', (
    tester,
  ) async {
    final vus = <String>[];
    await _pump(
      tester,
      cart: cartUsd,
      rates: [_usdVersCdf],
      onCurrencyChanged: (pivot, currency) => vus.add('$pivot>$currency'),
    );

    await tester.tap(find.text('FC'));
    await tester.pumpAndSettle();

    expect(vus, ['USD>CDF']);
  });
}
