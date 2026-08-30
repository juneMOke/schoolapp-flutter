import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_article_card.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_footer.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_line_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _polo = BoutiqueArticle(
  id: 'art-polo',
  academicYearId: 'ay-1',
  code: 'POLO',
  label: 'Polo Lacoste',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixParNiveau,
  levelPrices: {'humanites': 1500},
  currency: 'USD',
);

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('la carte annonce libellé, prix, famille et panier', (
    tester,
  ) async {
    // Sans le compteur, un utilisateur non voyant ajouterait un quatrième polo
    // sans savoir qu'il en a trois.
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 240,
          height: 220,
          child: BoutiqueArticleCard(
            article: _polo,
            quantityInCart: 3,
            canRemoveOne: true,
            onAdd: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(BoutiqueArticleCard));

    expect(semantics.label, contains('Polo Lacoste'));
    expect(semantics.label, contains('Uniforme'));
    expect(semantics.label, contains('3 au panier'));
  });

  testWidgets('le PAS d\'ajout est nommé, pas seulement dessiné', (
    tester,
  ) async {
    // La carte n'est plus le bouton : son pied l'est. Un « + » et un « − » sans
    // libellé se lisent « bouton, bouton » au lecteur d'écran — deux cibles
    // indiscernables sur un geste qui engage de l'argent.
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 240,
          height: 220,
          child: BoutiqueArticleCard(
            article: _polo,
            quantityInCart: 2,
            canRemoveOne: true,
            onAdd: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Ajouter un Polo Lacoste'), findsOneWidget);
    expect(find.bySemanticsLabel('Retirer un Polo Lacoste'), findsOneWidget);
  });

  testWidgets('article absent du panier : le geste est d\'AJOUTER', (
    tester,
  ) async {
    // À zéro, le pas n'aurait rien à retirer : le pied porte un bouton unique,
    // nommé, qui dit ce qu'il fait.
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 240,
          height: 220,
          child: BoutiqueArticleCard(
            article: _polo,
            quantityInCart: 0,
            canRemoveOne: false,
            onAdd: () {},
            onRemove: () {},
          ),
        ),
      ),
    );

    expect(find.text('Ajouter au panier'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsNothing);
  });

  testWidgets('une ligne non résolue annonce le manque AVANT le libellé', (
    tester,
  ) async {
    // Un lecteur d'écran doit annoncer le problème avant de décrire l'article,
    // pas après.
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 380,
          child: BoutiqueCartLineTile(
            line: const CartLine(key: 'k0', article: _polo),
            levels: const [],
            onRemove: () {},
            onQuantityChanged: (_) {},
            onLevelChanged: (_) {},
            onPickBeneficiary: () {},
            onClearBeneficiary: () {},
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(BoutiqueCartLineTile));

    expect(semantics.label, startsWith('Niveau requis'));
    expect(semantics.label, contains('Polo Lacoste'));
  });

  testWidgets('la liste des manques est une RÉGION VIVANTE', (tester) async {
    // Elle change à chaque frappe : un lecteur d'écran doit annoncer ce qui
    // reste sans qu'on aille le rechercher.
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 380,
          child: BoutiqueCartFooter(
            cart: const BoutiqueCart(
              payer: CartPayer(),
              lines: [CartLine(key: 'k0', article: _polo)],
            ),
            onCollect: null,
            onClear: () {},
          ),
        ),
      ),
    );

    // La région vivante porte le texte des manques.
    final live = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.liveRegion == true,
    );

    expect(live, findsOneWidget);
  });

  testWidgets('la couleur n\'est JAMAIS le seul signal', (tester) async {
    // Un daltonien tient une caisse aussi bien qu'un autre : la ligne ambre
    // porte aussi les mots.
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 380,
          child: BoutiqueCartLineTile(
            line: const CartLine(key: 'k0', article: _polo),
            levels: const [],
            onRemove: () {},
            onQuantityChanged: (_) {},
            onLevelChanged: (_) {},
            onPickBeneficiary: () {},
            onClearBeneficiary: () {},
          ),
        ),
      ),
    );

    expect(find.text('Prix à résoudre'), findsOneWidget);
    expect(find.textContaining('Niveau requis'), findsWidgets);
  });
}
