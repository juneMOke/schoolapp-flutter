import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

const String nbsp = '\u00A0';

void main() {
  group('decimalsOf — la devise décide, pas la valeur', () {
    test('le dollar en porte deux', () {
      expect(MoneyFormat.decimalsOf('USD'), 2);
    });

    test('le franc congolais n’en porte aucune', () {
      expect(MoneyFormat.decimalsOf('CDF'), 0);
      expect(MoneyFormat.decimalsOf(' cdf '), 0);
    });

    test('une devise inconnue en porte deux — le défaut sûr', () {
      // Zéro décimale escamoterait de l'argent ; deux n'en inventent pas.
      expect(MoneyFormat.decimalsOf('XAF'), 2);
      expect(MoneyFormat.decimalsOf(''), 2);
    });
  });

  group('symbolOf', () {
    test('les trois devises du contrat', () {
      expect(MoneyFormat.symbolOf('USD'), r'$');
      expect(MoneyFormat.symbolOf('CDF'), 'FC');
      expect(MoneyFormat.symbolOf('EUR'), '€');
    });

    test('normalise avant de résoudre', () {
      expect(MoneyFormat.symbolOf(' cdf '), 'FC');
    });

    test('une devise inconnue garde son code', () {
      expect(MoneyFormat.symbolOf('XAF'), 'XAF');
    });

    test('une devise vide ne produit aucun symbole', () {
      expect(MoneyFormat.symbolOf(''), isEmpty);
    });
  });

  group('format — les quatre cas de la règle', () {
    test('dollar rond : deux décimales quand même', () {
      expect(MoneyFormat.format(const Money(42500, 'USD')), '425,00$nbsp\$');
    });

    test('dollar avec cents', () {
      expect(MoneyFormat.format(const Money(42550, 'USD')), '425,50$nbsp\$');
    });

    test('franc rond : aucune décimale', () {
      expect(
        MoneyFormat.format(const Money(9000000, 'CDF')),
        '90${nbsp}000${nbsp}FC',
      );
    });

    test('franc qui porte réellement des centimes : ils s’affichent', () {
      // Une convention d'écriture ne doit jamais arrondir sous les yeux du
      // lecteur.
      expect(
        MoneyFormat.format(const Money(9000050, 'CDF')),
        '90${nbsp}000,50${nbsp}FC',
      );
    });
  });

  group('format — détails', () {
    test('groupe les milliers par trois', () {
      expect(
        MoneyFormat.format(const Money(123456700, 'CDF')),
        '1${nbsp}234${nbsp}567${nbsp}FC',
      );
    });

    test('un franc à centimes réels garde son groupement ET ses décimales', () {
      expect(
        MoneyFormat.format(const Money(123456789, 'CDF')),
        '1${nbsp}234${nbsp}567,89${nbsp}FC',
      );
    });

    test('ne groupe pas en dessous de mille', () {
      expect(MoneyFormat.format(const Money(99900, 'CDF')), '999${nbsp}FC');
    });

    test('zéro', () {
      expect(MoneyFormat.format(const Money(0, 'USD')), '0,00$nbsp\$');
      expect(MoneyFormat.format(const Money(0, 'CDF')), '0${nbsp}FC');
    });

    test('négatif', () {
      expect(MoneyFormat.format(const Money(-42500, 'USD')), '-425,00$nbsp\$');
    });

    test('une devise vide ne laisse pas d’espace orphelin', () {
      expect(MoneyFormat.format(const Money(42500, '')), '425,00');
    });

    test('la devise est normalisée avant d’être rendue', () {
      expect(
        MoneyFormat.format(const Money(9000000, 'cdf')),
        '90${nbsp}000${nbsp}FC',
      );
    });
  });

  group('format — le ticket thermique', () {
    test('utilise l’espace ordinaire, qu’une ESC/POS sait rendre', () {
      final rendered = MoneyFormat.format(
        const Money(9000000, 'CDF'),
        space: MoneyFormat.thermalSpace,
      );

      expect(rendered, '90 000 FC');
      expect(rendered.contains(nbsp), isFalse);
    });
  });

  group('amountOnly', () {
    test('rend le nombre sans abréviation', () {
      expect(MoneyFormat.amountOnly(const Money(42500, 'USD')), '425,00');
      expect(
        MoneyFormat.amountOnly(const Money(9000000, 'CDF')),
        '90${nbsp}000',
      );
    });
  });

  group('compact — les cartes du catalogue', () {
    test('escamote les décimales d’un montant rond', () {
      expect(MoneyFormat.compact(const Money(1000, 'USD')), '10$nbsp\$');
    });

    test('n’escamote jamais des centimes réels', () {
      expect(MoneyFormat.compact(const Money(1050, 'USD')), '10,50$nbsp\$');
    });

    test('groupe les milliers, comme le reste', () {
      expect(
        MoneyFormat.compact(const Money(9000000, 'CDF')),
        '90${nbsp}000${nbsp}FC',
      );
    });

    test('diffère de format sur un dollar rond, et seulement là', () {
      expect(
        MoneyFormat.compact(const Money(1000, 'USD')),
        isNot(MoneyFormat.format(const Money(1000, 'USD'))),
      );
      expect(
        MoneyFormat.compact(const Money(1050, 'USD')),
        MoneyFormat.format(const Money(1050, 'USD')),
      );
      expect(
        MoneyFormat.compact(const Money(9000000, 'CDF')),
        MoneyFormat.format(const Money(9000000, 'CDF')),
      );
    });
  });
}
