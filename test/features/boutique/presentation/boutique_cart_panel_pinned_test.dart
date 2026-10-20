import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_footer.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _polo = BoutiqueArticle(
  id: 'art-polo',
  academicYearId: 'ay-1',
  code: 'POLO',
  label: 'Polo',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixParNiveau,
  levelPrices: {'humanites': 1500},
  currency: 'USD',
);

/// La colonne du panier sur la caisse en grand écran : le pied reste en bas
/// quand la colonne est assez haute, et tout défile quand elle ne l'est plus.
void main() {
  Future<void> pump(WidgetTester tester, double height) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 420,
            height: height,
            child: BoutiqueCartPanel(
              pinFooter: true,
              cart: const BoutiqueCart(
                lines: [CartLine(key: 'k0', article: _polo)],
              ),
              levels: const [],
              payerSection: const SizedBox(height: 400),
              onRemoveLine: (_) {},
              onQuantityChanged: (_, _) {},
              onLevelChanged: (_, _) {},
              onPickBeneficiary: (_) {},
              onClearBeneficiary: (_) {},
              onCollect: () {},
              onClear: () {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('colonne haute : le pied épinglé en bas, le contenu défile', (
    tester,
  ) async {
    await pump(tester, 700);
    expect(tester.takeException(), isNull);
    final panelBottom = tester.getBottomLeft(find.byType(BoutiqueCartPanel)).dy;
    final footerBottom = tester
        .getBottomLeft(find.byType(BoutiqueCartFooter))
        .dy;
    expect(panelBottom - footerBottom, lessThan(40));
  });

  for (final height in [200.0, 300.0]) {
    testWidgets('colonne basse ($height) : rien ne déborde, tout défile', (
      tester,
    ) async {
      await pump(tester, height);
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  }
}
