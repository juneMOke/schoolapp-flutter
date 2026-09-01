import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

/// 1 $ = 1 666,67 FC — le taux de l'exemple du plan back.
const int _taux166667 = 1666670000;

ExchangeRate _rate({
  String base = 'USD',
  String quote = 'CDF',
  int rateMicros = _taux166667,
  DateTime? from,
  int? bandBp,
}) => ExchangeRate(
  base: base,
  quote: quote,
  rateMicros: rateMicros,
  effectiveFrom: from ?? DateTime.utc(2026, 9, 1),
  divergenceBandBp: bandBp,
);

void main() {
  group('convertCents — la conversion se fait en centimes des deux côtés', () {
    test('30,00 \$ valent 50 000,10 FC au taux de 1 666,67', () {
      // Le chiffre exact de l'arbitrage n° 3 : le franc s'affiche sans
      // décimales mais se stocke en centimes, et c'est de là que vient la
      // tolérance.
      expect(ExchangeRates.convertCents(3000, _rate()), 5000010);
    });

    test('le facteur ne dérape pas d’un ordre de grandeur', () {
      // Le piège du chantier : convertir des unités puis multiplier par 100.
      // 30 $ ne valent ni 500 FC ni 5 000 000 FC.
      final francs = ExchangeRates.convertCents(3000, _rate());
      expect(francs ~/ 100, 50000);
    });

    test('un taux d’identité rend le montant tel quel, sans arithmétique', () {
      expect(
        ExchangeRates.convertCents(4237, ExchangeRate.identity('USD')),
        4237,
      );
    });

    test('l’arrondi va au plus proche, la moitié s’éloignant de zéro', () {
      // 1 cent à 2,5 : 2,5 → 3, et -2,5 → -3. Toujours tronquer ferait perdre
      // un centime au parent à chaque ligne, systématiquement dans le même sens.
      final demi = _rate(rateMicros: 2500000);
      expect(ExchangeRates.convertCents(1, demi), 3);
      expect(ExchangeRates.convertCents(-1, demi), -3);
    });

    test('un très gros montant ne déborde pas', () {
      // Dix millions de dollars en centimes, à un taux à quatre chiffres :
      // le produit approche 2×10¹⁸. Calculé en int, il passerait de justesse ;
      // on ne parie pas là-dessus sur de l'argent.
      final cents = 1000000000;
      final resultat = ExchangeRates.convertCents(cents, _rate());
      expect(resultat, 1666670000000);
    });

    test('convert change la devise pour celle du taux', () {
      final recu = ExchangeRates.convert(const Money(3000, 'USD'), _rate());
      expect(recu.currency, 'CDF');
      expect(recu.amountInCents, 5000010);
    });
  });

  group('at — une série, jamais une valeur remplacée', () {
    test('rend le taux en vigueur, pas le dernier de la liste', () {
      final matin = _rate(
        rateMicros: 2500000000,
        from: DateTime.utc(2026, 9, 1, 6),
      );
      final midi = _rate(
        rateMicros: 2600000000,
        from: DateTime.utc(2026, 9, 1, 12),
      );

      final resolu = ExchangeRates.at(
        [midi, matin],
        base: 'USD',
        quote: 'CDF',
        moment: DateTime.utc(2026, 9, 1, 9),
      );

      expect(resolu, matin);
    });

    test('la borne est inclusive : un taux vaut dès son instant d’effet', () {
      final midi = _rate(from: DateTime.utc(2026, 9, 1, 12));
      expect(
        ExchangeRates.at(
          [midi],
          base: 'USD',
          quote: 'CDF',
          moment: DateTime.utc(2026, 9, 1, 12),
        ),
        midi,
      );
    });

    test('compare en UTC, quel que soit le fuseau du versement', () {
      final midiUtc = _rate(from: DateTime.utc(2026, 9, 1, 12));
      // 14h30 à Kinshasa (UTC+1) = 13h30 UTC : le taux de midi vaut.
      final kinshasa = DateTime.utc(2026, 9, 1, 13, 30).toLocal();
      expect(
        ExchangeRates.at(
          [midiUtc],
          base: 'USD',
          quote: 'CDF',
          moment: kinshasa,
        ),
        midiUtc,
      );
    });

    test('un versement antérieur à toute la série ne résout rien', () {
      // `null`, jamais une exception : une lecture ne remonte jamais d'erreur,
      // et l'écran taira la bascule plutôt que d'appliquer un 1 par défaut.
      expect(
        ExchangeRates.at(
          [_rate(from: DateTime.utc(2026, 9, 1))],
          base: 'USD',
          quote: 'CDF',
          moment: DateTime.utc(2026, 8, 31),
        ),
        isNull,
      );
    });

    test('la paire est respectée dans son sens', () {
      final rates = [_rate()];
      expect(
        ExchangeRates.at(
          rates,
          base: 'CDF',
          quote: 'USD',
          moment: DateTime.utc(2026, 9, 2),
        ),
        isNull,
      );
    });

    test('les devises demandées sont normalisées', () {
      final rate = _rate();
      expect(
        ExchangeRates.at(
          [rate],
          base: ' usd ',
          quote: 'cdf',
          moment: DateTime.utc(2026, 9, 2),
        ),
        rate,
      );
    });

    test('une série vide ne résout rien', () {
      expect(
        ExchangeRates.at(
          const <ExchangeRate>[],
          base: 'USD',
          quote: 'CDF',
          moment: DateTime.utc(2026, 9, 2),
        ),
        isNull,
      );
    });
  });

  group('ExchangeRate', () {
    test('parse normalise les devises', () {
      final rate = ExchangeRate.parse(
        base: ' usd ',
        quote: 'cdf',
        rateMicros: _taux166667,
        effectiveFrom: DateTime.utc(2026, 9, 1),
      );
      expect(rate.base, 'USD');
      expect(rate.quote, 'CDF');
    });

    test('identity vaut 1, dans une seule devise', () {
      final identite = ExchangeRate.identity('cdf');
      expect(identite.isIdentity, isTrue);
      expect(identite.rateMicros, ExchangeRate.scale);
      expect(identite.base, 'CDF');
      expect(identite.quote, 'CDF');
    });

    test(
      'un taux de 1 entre deux devises différentes n’est pas une identité',
      () {
        // Un dollar contre un franc au taux de 1 est une saisie fausse, pas le
        // cas courant : le distinguer est ce qui permet de le signaler.
        final suspect = _rate(rateMicros: ExchangeRate.scale);
        expect(suspect.isIdentity, isFalse);
      },
    );

    test('le taux affiché est celui qui est stocké', () {
      // Deux décimales à la saisie : l'imprimé et le stocké sont le même
      // nombre, sans quoi le parent ne retombe pas sur son total.
      expect(_rate().rateForDisplay, 1666.67);
    });
  });

  group('displayUnitInCents — la tolérance de l’invariant', () {
    test('vaut 1 FC en francs, 0,01 \$ en dollars', () {
      expect(MoneyFormat.displayUnitInCents('CDF'), 100);
      expect(MoneyFormat.displayUnitInCents('USD'), 1);
    });

    test('couvre l’écart de conversion de 30,00 \$ à 1 666,67', () {
      // 50 000,10 FC contre 50 000 FC attendus : 10 centimes d'écart, sous
      // l'unité d'affichage du franc. Refuser cet écart, c'est refuser des
      // versements justes.
      final ecart = (ExchangeRates.convertCents(3000, _rate()) - 5000000).abs();
      expect(ecart, lessThanOrEqualTo(MoneyFormat.displayUnitInCents('CDF')));
    });

    test('une devise inconnue prend la tolérance la plus fine', () {
      expect(MoneyFormat.displayUnitInCents('XAF'), 1);
    });
  });
}
