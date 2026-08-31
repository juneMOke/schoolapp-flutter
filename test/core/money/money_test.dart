import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';

void main() {
  group('CurrencyCode.normalize', () {
    test('met en majuscules et retire les espaces', () {
      expect(CurrencyCode.normalize(' usd '), 'USD');
      expect(CurrencyCode.normalize('cdf'), 'CDF');
      expect(CurrencyCode.normalize('USD'), 'USD');
    });

    test('laisse passer un code inconnu au lieu de le rejeter', () {
      // Une devise que le serveur ajouterait demain ne doit jamais faire
      // échouer la lecture d'un lot : de l'argent encaissé deviendrait
      // invisible au pull.
      expect(CurrencyCode.normalize('xaf'), 'XAF');
    });

    test('une chaîne vide reste vide', () {
      // État réel du grand-livre local, pas une anomalie à faire remonter.
      expect(CurrencyCode.normalize(''), '');
      expect(CurrencyCode.normalize('   '), '');
    });
  });

  group('Money', () {
    test('le constructeur const ne normalise pas', () {
      // Contrat assumé : la canonicalisation est la charge des frontières.
      expect(const Money(1, 'usd').currency, 'usd');
    });

    test('parse normalise la devise', () {
      expect(Money.parse(42500, ' usd '), const Money(42500, 'USD'));
    });

    test('égalité par valeur', () {
      expect(const Money(42500, 'USD'), const Money(42500, 'USD'));
      expect(const Money(42500, 'USD'), isNot(const Money(42500, 'CDF')));
      expect(const Money(42500, 'USD'), isNot(const Money(42501, 'USD')));
    });

    test('isZero', () {
      expect(const Money(0, 'USD').isZero, isTrue);
      expect(const Money(-1, 'USD').isZero, isFalse);
      expect(const Money(1, 'USD').isZero, isFalse);
    });

    test('accepte une devise vide sans lever', () {
      expect(Money.parse(1200, '').currency, isEmpty);
    });
  });
}
