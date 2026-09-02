import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';

/// Comment le panier retient ce que le client règle, et dans quelle monnaie.
///
/// Le règlement est porté **par devise de catalogue**, jamais par ligne : trois
/// cahiers du même prix se règlent d'un seul geste, et c'est le sous-total qui
/// pose la question.
const _polo = BoutiqueArticle(
  id: 'art-polo',
  academicYearId: 'ay-1',
  code: 'POLO',
  label: 'Polo',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 5000,
  currency: 'USD',
);

const _manuel = BoutiqueArticle(
  id: 'art-manuel',
  academicYearId: 'ay-1',
  code: 'MANUEL',
  label: 'Manuel',
  family: ArticleFamily.fournitures,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 9000000,
  currency: 'CDF',
);

void main() {
  const cart = BoutiqueCart(
    lines: [
      CartLine(key: 'k0', article: _polo),
      CartLine(key: 'k1', article: _manuel),
    ],
  );

  test('sans rien choisir, chaque devise se règle dans la sienne', () {
    expect(cart.tenderFor('USD').currency, isEmpty);
    expect(cart.tenderFor('USD').isConvertedFrom('USD'), isFalse);
  });

  test('choisir une autre monnaie ne touche QUE cette devise', () {
    final next = cart.withTenderCurrency('USD', 'CDF');

    expect(next.tenderFor('USD').currency, 'CDF');
    expect(
      next.tenderFor('CDF').currency,
      isEmpty,
      reason: 'les manuels sont déjà en francs : rien n’a à changer pour eux',
    );
  });

  test(
    'revenir à la devise du catalogue efface le montant qui l’accompagnait',
    () {
      final converti = cart
          .withTenderCurrency('USD', 'CDF')
          .withTenderedAmount('USD', 15000000);
      expect(converti.tenderFor('USD').tenderedCents, 15000000);

      final revenu = converti.withTenderCurrency('USD', 'USD');

      expect(revenu.tenderFor('USD').currency, isEmpty);
      expect(
        revenu.tenderFor('USD').tenderedCents,
        isNull,
        reason:
            'un montant saisi pour des francs ne doit pas ressortir sur un '
            'règlement en dollars',
      );
    },
  );

  test('un montant tendu sans devise choisie n’a rien à porter', () {
    // Le dû EST le tendu : un champ de plus ne dirait rien, et le retenir
    // ferait ressortir un chiffre le jour où une devise est choisie.
    final next = cart.withTenderedAmount('USD', 15000000);

    expect(next.tenderFor('USD').tenderedCents, isNull);
  });

  test('vider la dernière ligne d’une devise emporte son règlement', () {
    // Sans cette purge, « le client règle en francs » resterait orphelin et
    // ressortirait au prochain article en dollars ajouté — avec un montant
    // saisi pour un panier qui n'existe plus.
    final next = cart
        .withTenderCurrency('USD', 'CDF')
        .withTenderedAmount('USD', 15000000)
        .removeLine('k0');

    expect(next.tenders.containsKey('USD'), isFalse);
    expect(next.currencies, {'CDF'});
  });

  test('le règlement survit à un changement de quantité', () {
    final next = cart.withTenderCurrency('USD', 'CDF').setQuantity('k0', 3);

    expect(next.tenderFor('USD').currency, 'CDF');
  });

  test('le règlement fait partie de l’identité du panier', () {
    expect(
      cart.withTenderCurrency('USD', 'CDF'),
      isNot(cart),
      reason: 'sinon l’écran ne se redessine pas quand la monnaie change',
    );
  });

  test('« Nouvelle vente » repart sans aucun règlement', () {
    expect(cart.withTenderCurrency('USD', 'CDF').cleared().tenders, isEmpty);
  });
}
