import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';

const _ecusson = BoutiqueArticle(
  id: 'art-ecu',
  academicYearId: 'ay-1',
  code: 'ECUS',
  label: 'Écusson brodé',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 1000,
  currency: 'USD',
);

int _n = 0;
String _key() => 'k${_n++}';

/// Le jour de la vente, porté par le panier (BQ-19).
void main() {
  // Mardi 21 octobre 2026, 14 h 30 au guichet — à Kinshasa (UTC+1).
  final now = DateTime.utc(2026, 10, 21, 13, 30, 5, 120);

  setUp(() => _n = 0);

  group('soldAtFor — l\'heure métier de la vente', () {
    test('sans jour choisi : l\'instant de l\'encaissement, tel quel', () {
      expect(const BoutiqueCart().soldAtFor(now), now);
    });

    test('le jour même, choisi explicitement : l\'instant, tel quel', () {
      final cart = const BoutiqueCart().withSaleDate(DateTime(2026, 10, 21));
      expect(cart.soldAtFor(now), now);
      expect(cart.isBackdatedAt(now), isFalse);
    });

    test('antidatée : le jour choisi à l\'heure RÉELLE, pas minuit', () {
      // Minuit ferait de toutes les ventes antidatées d'un même jour des
      // ventes simultanées, et le ticket imprimerait une heure inventée.
      final cart = const BoutiqueCart().withSaleDate(DateTime(2026, 10, 19));
      expect(cart.soldAtFor(now), DateTime.utc(2026, 10, 19, 13, 30, 5, 120));
      expect(cart.isBackdatedAt(now), isTrue);
    });

    test('le panier passé minuit sans choix n\'est PAS antidaté', () {
      // Composé à 23 h 58, encaissé à 0 h 01 : c'est `null` qui protège.
      const cart = BoutiqueCart();
      // 0 h 01 le 22 à Kinshasa = 23 h 01 UTC le 21.
      final afterMidnight = DateTime.utc(2026, 10, 21, 23, 1);
      expect(cart.isBackdatedAt(afterMidnight), isFalse);
      expect(cart.soldAtFor(afterMidnight), afterMidnight);
    });
  });

  test('withSaleDate ne garde que le jour', () {
    final cart = const BoutiqueCart().withSaleDate(
      DateTime(2026, 10, 19, 17, 45),
    );
    expect(cart.saleDate, DateTime(2026, 10, 19));
  });

  test('le jour se lit à KINSHASA, pas à l\'heure de la tablette', () {
    // 23 h 30 UTC le 20 = 0 h 30 le 21 à l'école : le 20 est déjà « hier ».
    final lateUtc = DateTime.utc(2026, 10, 20, 23, 30);
    final cart = const BoutiqueCart().withSaleDate(DateTime(2026, 10, 20));
    expect(cart.isBackdatedAt(lateUtc), isTrue);
    // Relue à Kinshasa, la vente tombe le 20 à 0 h 30 — le jour choisi.
    expect(cart.soldAtFor(lateUtc), DateTime.utc(2026, 10, 19, 23, 30));
  });

  test('isFutureAt : seul un jour postérieur l\'est', () {
    expect(
      const BoutiqueCart().withSaleDate(DateTime(2026, 10, 22)).isFutureAt(now),
      isTrue,
    );
    expect(
      const BoutiqueCart().withSaleDate(DateTime(2026, 10, 21)).isFutureAt(now),
      isFalse,
    );
    expect(const BoutiqueCart().isFutureAt(now), isFalse);
  });

  test('le jour choisi survit à TOUS les gestes du panier', () {
    // Chaque geste reconstruit le panier : un seul constructeur qui l'oublie
    // ramènerait la vente à aujourd'hui sans un mot.
    final day = DateTime(2026, 10, 19);
    var cart = const BoutiqueCart().withSaleDate(day);
    cart = cart.addArticle(_ecusson, keyOf: _key);
    expect(cart.saleDate, day);
    final key = cart.lines.single.key;
    cart = cart.setQuantity(key, 3);
    expect(cart.saleDate, day);
    cart = cart.withPayer(const CartPayer(lastName: 'Ndombo'));
    expect(cart.saleDate, day);
    cart = cart.withTenderCurrency('USD', 'CDF');
    expect(cart.saleDate, day);
    cart = cart.withTenderedAmount('USD', 300000);
    expect(cart.saleDate, day);
    cart = cart.setSize(key, 'M');
    expect(cart.saleDate, day);
    cart = cart.removeLine(key);
    expect(cart.saleDate, day);
  });

  test('« Vider » et « Nouvelle vente » reposent aujourd\'hui', () {
    final cart = const BoutiqueCart()
        .withSaleDate(DateTime(2026, 10, 19))
        .cleared();
    expect(cart.saleDate, isNull);
  });

  test('deux paniers ne diffèrent que par le jour : ils sont DIFFÉRENTS', () {
    // Sans le jour dans l'égalité, le bloc n'émettrait pas le changement et
    // l'écran resterait sur l'ancienne date.
    expect(
      const BoutiqueCart().withSaleDate(DateTime(2026, 10, 19)),
      isNot(const BoutiqueCart()),
    );
  });
}
