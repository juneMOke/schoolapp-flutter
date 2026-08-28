import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/domain/fee_amount.dart';

void main() {
  group('saisie vers centimes', () {
    test('la virgule décimale française est acceptée', () {
      expect(FeeAmount.centsFromInput('8000,00'), 800000);
      expect(FeeAmount.centsFromInput('680,50'), 68050);
    });

    test('le point décimal aussi', () {
      expect(FeeAmount.centsFromInput('680.50'), 68050);
    });

    test('les espaces de milliers sont ignorés', () {
      expect(FeeAmount.centsFromInput('8 000,00'), 800000);
      expect(FeeAmount.centsFromInput('8 000,00'), 800000);
    });

    test('un centime ne se perd pas dans le flottant', () {
      // (80.07 * 100).toInt() vaut 8006 : la représentation binaire de 80,07
      // est 80,069999…, et la troncature emporte le centime. Arrondir ferme ce
      // trou — c'est le seul endroit du module où l'argent peut se perdre.
      expect(FeeAmount.centsFromInput('80,07'), 8007);
      expect(FeeAmount.centsFromInput('1,10'), 110);
      expect(FeeAmount.centsFromInput('29,29'), 2929);
      expect(FeeAmount.centsFromInput('1155,57'), 115557);
    });

    test('une saisie vide ou illisible ne rend pas zéro', () {
      // Zéro serait un montant valide, et un frais gratuit qu'on n'a pas voulu
      // saisir passerait la validation.
      expect(FeeAmount.centsFromInput(''), isNull);
      expect(FeeAmount.centsFromInput('gratuit'), isNull);
      expect(FeeAmount.centsFromInput('  '), isNull);
    });

    test('un montant négatif est refusé', () {
      expect(FeeAmount.centsFromInput('-50'), isNull);
    });

    test('zéro est lisible, c\'est la validation qui le refusera', () {
      expect(FeeAmount.centsFromInput('0'), 0);
    });
  });

  group('centimes vers affichage', () {
    test('le franc congolais s\'affiche FC, mais circule CDF', () {
      expect(FeeAmount.display(800000, 'CDF'), contains('FC'));
      expect(FeeAmount.displayCurrency('CDF'), 'FC');
      expect(FeeAmount.displayCurrency('USD'), 'USD');
    });

    test('un aller-retour saisie conserve le montant', () {
      expect(FeeAmount.inputFromCents(68050), '680,50');
      expect(FeeAmount.centsFromInput(FeeAmount.inputFromCents(68050)), 68050);
    });
  });

  group('totaux par devise', () {
    test('deux devises ne s\'additionnent jamais', () {
      // 100 USD et 100 CDF ne font pas 200 de quoi que ce soit.
      final totals = FeeAmount.totalsByCurrency([
        (currency: 'USD', amountInCents: 7500),
        (currency: 'USD', amountInCents: 68000),
        (currency: 'CDF', amountInCents: 800000),
      ]);

      expect(totals['USD'], 75500);
      expect(totals['CDF'], 800000);
      expect(totals.keys, hasLength(2));
    });

    test('aucun frais, aucun total', () {
      expect(FeeAmount.totalsByCurrency(const []), isEmpty);
    });
  });
}
