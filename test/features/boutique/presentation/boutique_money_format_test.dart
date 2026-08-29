import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';

void main() {
  group('forme abrégée (cartes)', () {
    test('un montant rond s\'abrège', () {
      expect(BoutiqueMoneyFormat.compact(1000, 'USD'), r'10 $');
    });

    test('des centimes NON nuls ne s\'escamotent jamais', () {
      // C'est le seul endroit où l'abrégé pourrait mentir : « 10 $ » pour
      // 10,50 $ ferait recompter le ticket au client.
      expect(BoutiqueMoneyFormat.compact(1050, 'USD'), r'10.50 $');
    });

    test('une autre devise garde son code', () {
      // Inventer un symbole pour le franc congolais ferait lire « 10 F » là où
      // l'école écrit « 10 FC ».
      expect(BoutiqueMoneyFormat.compact(1000, 'CDF'), '10 CDF');
    });
  });

  group('forme exacte (totaux et documents)', () {
    test('toujours deux décimales — un ticket se recompte', () {
      expect(BoutiqueMoneyFormat.exact(3500, 'USD'), r'35.00 $');
      expect(BoutiqueMoneyFormat.exact(0, 'USD'), r'0.00 $');
    });

    test('les cents ne passent jamais par un arrondi visible', () {
      expect(BoutiqueMoneyFormat.exact(1, 'USD'), r'0.01 $');
      expect(BoutiqueMoneyFormat.exact(999999, 'USD'), r'9999.99 $');
    });
  });
}
