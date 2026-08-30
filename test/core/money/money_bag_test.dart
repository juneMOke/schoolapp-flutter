import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Une créance factice, pour exercer [MoneyBag.sumBy] sur autre chose que des
/// `Money` déjà tout faits — c'est ainsi qu'il sera appelé partout.
class _Charge {
  final int cents;
  final String currency;
  const _Charge(this.cents, this.currency);
}

void main() {
  group('MoneyBag — construction', () {
    test('vide', () {
      expect(MoneyBag.empty.isEmpty, isTrue);
      expect(MoneyBag.empty.isNotEmpty, isFalse);
      expect(MoneyBag.empty.length, 0);
      expect(MoneyBag.of(const <Money>[]), MoneyBag.empty);
    });

    test('somme les montants d’une même devise', () {
      final bag = MoneyBag.of(const [Money(42500, 'USD'), Money(1500, 'USD')]);

      expect(bag.entries, const [Money(44000, 'USD')]);
    });

    test('garde les devises séparées', () {
      final bag = MoneyBag.of(const [
        Money(42500, 'USD'),
        Money(9000000, 'CDF'),
      ]);

      expect(bag.length, 2);
      expect(bag.amountIn('USD'), const Money(42500, 'USD'));
      expect(bag.amountIn('CDF'), const Money(9000000, 'CDF'));
    });

    test('normalise la casse : « usd » et « USD » ne font qu’une entrée', () {
      final bag = MoneyBag.of(const [
        Money(100, 'usd'),
        Money(200, 'USD'),
        Money(300, ' Usd '),
      ]);

      expect(bag.entries, const [Money(600, 'USD')]);
    });

    test('trie par code de devise croissant', () {
      final bag = MoneyBag.of(const [
        Money(1, 'USD'),
        Money(2, 'EUR'),
        Money(3, 'CDF'),
      ]);

      expect(bag.currencies, ['CDF', 'EUR', 'USD']);
    });

    test('groupe la devise vide à part, sans lever', () {
      final bag = MoneyBag.of(const [Money(100, ''), Money(200, 'USD')]);

      expect(bag.length, 2);
      expect(bag.amountIn(''), const Money(100, ''));
    });

    test('from : un seul montant', () {
      expect(MoneyBag.from(const Money(42500, 'USD')).entries, const [
        Money(42500, 'USD'),
      ]);
    });

    test('sumBy groupe par devise, jamais toutes devises confondues', () {
      const charges = [
        _Charge(42500, 'USD'),
        _Charge(9000000, 'CDF'),
        _Charge(1500, 'USD'),
      ];

      final bag = MoneyBag.sumBy(
        charges,
        (charge) => Money.parse(charge.cents, charge.currency),
      );

      expect(bag.entries, const [Money(9000000, 'CDF'), Money(44000, 'USD')]);
    });

    test('les entrées ne sont pas modifiables', () {
      final bag = MoneyBag.of(const [Money(1, 'USD')]);

      expect(
        () => bag.entries.add(const Money(2, 'CDF')),
        throwsUnsupportedError,
      );
    });
  });

  group('MoneyBag — vide n’est pas zéro', () {
    test('un sac vide et un sac à zéro ne sont pas égaux', () {
      // La distinction porte tout le rendu : « il ne doit rien, dans aucune
      // unité » n'est pas « en dollars, il ne reste rien ».
      expect(MoneyBag.empty, isNot(MoneyBag.of(const [Money(0, 'USD')])));
    });

    test('isAllZero est vrai pour le sac vide comme pour un sac à zéro', () {
      expect(MoneyBag.empty.isAllZero, isTrue);
      expect(MoneyBag.of(const [Money(0, 'USD')]).isAllZero, isTrue);
      expect(MoneyBag.of(const [Money(1, 'USD')]).isAllZero, isFalse);
    });

    test('withoutZeros élague les entrées nulles et garde l’ordre', () {
      final bag = MoneyBag.of(const [
        Money(0, 'USD'),
        Money(9000000, 'CDF'),
        Money(0, 'EUR'),
      ]);

      expect(bag.withoutZeros.entries, const [Money(9000000, 'CDF')]);
    });

    test('withoutZeros d’un sac tout à zéro rend un sac vide', () {
      final bag = MoneyBag.of(const [Money(0, 'USD'), Money(0, 'CDF')]);

      expect(bag.withoutZeros.isEmpty, isTrue);
    });
  });

  group('MoneyBag — bascule mono / multi', () {
    test('soleEntry rend le montant quand il n’y en a qu’un', () {
      expect(
        MoneyBag.of(const [Money(42500, 'USD')]).soleEntry,
        const Money(42500, 'USD'),
      );
    });

    test('soleEntry est nul quand le sac est vide', () {
      expect(MoneyBag.empty.soleEntry, isNull);
    });

    test('soleEntry est nul dès qu’il y a deux devises', () {
      final bag = MoneyBag.of(const [
        Money(42500, 'USD'),
        Money(9000000, 'CDF'),
      ]);

      expect(bag.soleEntry, isNull);
      expect(bag.isMultiCurrency, isTrue);
    });

    test('isMultiCurrency est faux à zéro et à une devise', () {
      expect(MoneyBag.empty.isMultiCurrency, isFalse);
      expect(
        MoneyBag.of(const [Money(1, 'USD'), Money(2, 'USD')]).isMultiCurrency,
        isFalse,
      );
    });
  });

  group('MoneyBag — lecture et fusion', () {
    test('amountIn normalise la devise demandée', () {
      final bag = MoneyBag.of(const [Money(42500, 'USD')]);

      expect(bag.amountIn(' usd '), const Money(42500, 'USD'));
    });

    test('amountIn rend null pour une devise absente', () {
      // Absente et « zéro dans cette devise » sont deux réponses distinctes.
      expect(MoneyBag.of(const [Money(1, 'USD')]).amountIn('CDF'), isNull);
    });

    test('l’addition fusionne devise par devise', () {
      final left = MoneyBag.of(const [Money(42500, 'USD')]);
      final right = MoneyBag.of(const [
        Money(1500, 'USD'),
        Money(9000000, 'CDF'),
      ]);

      expect((left + right).entries, const [
        Money(9000000, 'CDF'),
        Money(44000, 'USD'),
      ]);
    });

    test('l’addition est commutative', () {
      final left = MoneyBag.of(const [Money(42500, 'USD')]);
      final right = MoneyBag.of(const [Money(9000000, 'CDF')]);

      expect(left + right, right + left);
    });

    test('ajouter le sac vide ne change rien', () {
      final bag = MoneyBag.of(const [Money(42500, 'USD')]);

      expect(bag + MoneyBag.empty, bag);
    });

    test(
      'deux sacs de mêmes montants sont égaux quel que soit l’ordre reçu',
      () {
        // C'est cette égalité qui portera le fail-fast du guichet : comparer le
        // versement à la somme de ses imputations, devise par devise.
        final left = MoneyBag.of(const [
          Money(42500, 'USD'),
          Money(9000000, 'CDF'),
        ]);
        final right = MoneyBag.of(const [
          Money(9000000, 'CDF'),
          Money(42500, 'USD'),
        ]);

        expect(left, right);
      },
    );

    test('deux sacs mal répartis mais de même total global diffèrent', () {
      // Le cas exact que `ALLOCATION_SUM_MISMATCH` refuse désormais côté
      // serveur : le total global colle, la répartition non.
      final declared = MoneyBag.of(const [
        Money(1000, 'USD'),
        Money(2000, 'CDF'),
      ]);
      final allocated = MoneyBag.of(const [
        Money(2000, 'USD'),
        Money(1000, 'CDF'),
      ]);

      expect(declared, isNot(allocated));
    });
  });

  group('MoneyBag — diagnostic', () {
    test('toString nomme chaque devise', () {
      final bag = MoneyBag.of(const [
        Money(42500, 'USD'),
        Money(9000000, 'CDF'),
      ]);

      expect(bag.toString(), 'MoneyBag(9000000 CDF · 42500 USD)');
    });
  });
}
