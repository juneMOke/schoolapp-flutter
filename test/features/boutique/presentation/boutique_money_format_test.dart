import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';

const String nbsp = ' ';

/// La caisse écrit désormais comme le reste de l'application : `MoneyFormat`
/// porte la règle, et ces méthodes n'en sont plus que des façades.
///
/// Trois choses ont changé, et chacune était un écart :
///  - le **point** décimal devient une **virgule** (le reste de l'app écrivait
///    déjà « 425,00 ») ;
///  - `CDF` s'écrit « FC », l'abréviation que l'école emploie — l'ancien test
///    épinglait « 10 CDF » alors que son propre commentaire réclamait « 10 FC » ;
///  - les milliers se groupent, comme partout ailleurs.
void main() {
  group('forme abrégée (cartes)', () {
    test('un montant rond s\'abrège', () {
      expect(BoutiqueMoneyFormat.compact(1000, 'USD'), '10$nbsp\$');
    });

    test('des centimes NON nuls ne s\'escamotent jamais', () {
      // C'est le seul endroit où l'abrégé pourrait mentir : « 10 $ » pour
      // 10,50 $ ferait recompter le ticket au client.
      expect(BoutiqueMoneyFormat.compact(1050, 'USD'), '10,50$nbsp\$');
    });

    test('le franc s\'écrit comme l\'école l\'écrit', () {
      expect(BoutiqueMoneyFormat.compact(1000, 'CDF'), '10${nbsp}FC');
    });

    test('une devise inconnue garde son code', () {
      // Inventer un symbole ferait lire autre chose que le réel.
      expect(BoutiqueMoneyFormat.compact(1000, 'XAF'), '10${nbsp}XAF');
    });
  });

  group('forme exacte (totaux et documents)', () {
    test('deux décimales sur le dollar — un ticket se recompte', () {
      expect(BoutiqueMoneyFormat.exact(3500, 'USD'), '35,00$nbsp\$');
      expect(BoutiqueMoneyFormat.exact(0, 'USD'), '0,00$nbsp\$');
    });

    test('aucune décimale sur le franc — le centime n\'y circule pas', () {
      expect(
        BoutiqueMoneyFormat.exact(9000000, 'CDF'),
        '90${nbsp}000${nbsp}FC',
      );
    });

    test('les cents ne passent jamais par un arrondi visible', () {
      expect(BoutiqueMoneyFormat.exact(1, 'USD'), '0,01$nbsp\$');
      expect(BoutiqueMoneyFormat.exact(999999, 'USD'), '9${nbsp}999,99$nbsp\$');
    });

    test('un franc qui porte des centimes réels les garde', () {
      expect(
        BoutiqueMoneyFormat.exact(9000050, 'CDF'),
        '90${nbsp}000,50${nbsp}FC',
      );
    });
  });

  group('symbolOf', () {
    test('délègue au socle', () {
      expect(BoutiqueMoneyFormat.symbolOf('usd'), MoneyFormat.symbolOf('USD'));
      expect(BoutiqueMoneyFormat.symbolOf('CDF'), 'FC');
    });
  });
}
