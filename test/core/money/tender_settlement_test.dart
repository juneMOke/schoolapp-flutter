import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';

/// Dans quelle monnaie CHAQUE frais est réglé, et à quel taux.
///
/// Trois propriétés portent tout l'écran : le cas courant ne coûte rien (régler
/// dans la devise de la créance ⇒ l'identité, donc l'écran d'avant), le guichet
/// ne propose que ce que le référentiel sait convertir (un champ de taux vide
/// serait un chiffre à fabriquer), et **les deux montants d'une ligne se
/// déduisent l'un de l'autre sans jamais éteindre plus que ce qui est posé sur
/// le comptoir**.
const int _taux2800 = 2800000000;

final _usdVersCdf = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: _taux2800,
  effectiveFrom: DateTime.utc(2026, 9, 1, 6),
  divergenceBandBp: 200,
);

TenderSettlement _settlement({
  List<ExchangeRate>? rates,
  Map<String, int>? overrides,
}) => TenderSettlement(
  rates: rates ?? [_usdVersCdf],
  at: DateTime.utc(2026, 9, 1, 10),
  overriddenRates: overrides ?? const {},
);

void main() {
  group('optionsFor — le guichet propose, il n’invente pas', () {
    test('la devise de la créance vient toujours en tête', () {
      expect(_settlement().optionsFor('USD').first, 'USD');
    });

    test('une devise convertible depuis ce frais est proposée', () {
      expect(_settlement().optionsFor('USD'), ['USD', 'CDF']);
    });

    test(
      'un frais dont la devise n’a aucun taux sortant n’a rien à proposer',
      () {
        // Le référentiel porte USD→CDF, pas CDF→USD : une créance en francs ne
        // peut donc pas se régler en dollars, et la ligne n'affiche aucun
        // sélecteur plutôt qu'un champ où le taux se fabriquerait.
        expect(_settlement().optionsFor('CDF'), ['CDF']);
      },
    );

    test('sans aucun taux paramétré, il n’y a rien à choisir', () {
      expect(_settlement(rates: const []).optionsFor('USD'), ['USD']);
    });

    test('un taux qui n’a pas encore commencé se propose quand même — le repli '
        'd’horloge, et son revers', () {
      // Le serveur ne descend que des points RÉSOLVABLES : celui en vigueur,
      // et ceux datés au-delà. Une tablette dont l'horloge retarde les voit
      // tous dans son futur ; sans repli elle n'aurait plus aucun taux, alors
      // qu'elle vient d'en recevoir la série. Un guichet sans taux invente.
      //
      // Le revers est assumé : un PREMIER taux programmé pour demain
      // s'applique dès aujourd'hui. C'est le prix de la règle de résolution
      // que le bundle serveur demande au client, et le guichet est le seul à
      // le payer — l'écran de direction, lui, garde la vérité stricte.
      final futur = ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        rateMicros: _taux2800,
        effectiveFrom: DateTime.utc(2026, 9, 2),
      );

      expect(_settlement(rates: [futur]).optionsFor('USD'), ['USD', 'CDF']);
    });

    test('le point en vigueur prime toujours sur celui de demain', () {
      // Le repli ne s'active QUE si rien n'a commencé : tant qu'un point est en
      // vigueur, un taux programmé ne l'écrase pas.
      final demain = ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        rateMicros: 3000000000,
        effectiveFrom: DateTime.utc(2026, 9, 2),
      );

      expect(
        _settlement(
          rates: [_usdVersCdf, demain],
        ).rateFor('USD', 'CDF')?.rateMicros,
        _taux2800,
      );
    });
  });

  group('le cas courant ne coûte rien', () {
    test('régler dans la devise de la créance n’est pas une conversion', () {
      final line = _settlement().fromSettled(
        settledCurrency: 'USD',
        tenderCurrency: 'USD',
        settledCents: 5000,
      );

      expect(line.isConverted, isFalse);
      expect(line.rate, isNull);
      expect(line.tenderCents, 5000);
      expect(line.changeCents, 0);
    });
  });

  group('les deux montants d’une ligne', () {
    test('l’imputé donne exactement ce qu’il faut compter', () {
      final line = _settlement().fromSettled(
        settledCurrency: 'USD',
        tenderCurrency: 'CDF',
        settledCents: 5000, // 50,00 $
      );

      expect(line.isConverted, isTrue);
      expect(line.tenderCents, 14000000); // 140 000 FC
      expect(line.changeCents, 0);
    });

    test('le montant posé sur le comptoir éteint vers le BAS, et le reste est '
        'de la monnaie à rendre', () {
      // 50 000 FC à 2 800 valent 17,857… $ : ni 17,85 ni 17,86 ne retombent
      // sur 50 000. On impute 17,85 — soit 49 980 FC — et 20 FC repartent.
      final line = _settlement().fromTender(
        settledCurrency: 'USD',
        tenderCurrency: 'CDF',
        tenderedCents: 5000000, // 50 000 FC
      );

      expect(line.settledCents, 1785);
      expect(line.tenderCents, 4998000);
      expect(line.changeCents, 2000); // 20 FC
    });

    test('arrondir au plus proche éteindrait ce que personne n’a posé — et le '
        'serveur refuserait le couple', () {
      final line = _settlement().fromTender(
        settledCurrency: 'USD',
        tenderCurrency: 'CDF',
        tenderedCents: 5000000,
      );

      expect(
        line.settledCents,
        lessThan(1786),
        reason:
            '17,86 \$ valent 50 008 FC : huit francs de plus que ce que le '
            'parent a tendu',
      );
      expect(
        TenderComposition.check(
          allocations: [line.settled],
          tenders: _settlement().tendersFor([line]),
        ),
        isNull,
        reason: 'ce que le helper compose passe la garde du chemin d’écriture',
      );
    });

    test('le tiroir ne garde jamais la monnaie rendue', () {
      final line = _settlement().fromTender(
        settledCurrency: 'USD',
        tenderCurrency: 'CDF',
        tenderedCents: 5000000,
      );

      expect(
        line.tenderCents + line.changeCents,
        5000000,
        reason: 'le tender est le NET conservé, jamais le montant présenté',
      );
    });
  });

  group('tendersFor — on découpe sur l’unité, jamais sur le geste', () {
    test('deux frais de même paire ne font qu’une ligne d’encaissement', () {
      final settlement = _settlement();
      final lines = [
        settlement.fromSettled(
          settledCurrency: 'USD',
          tenderCurrency: 'CDF',
          settledCents: 5000,
        ),
        settlement.fromSettled(
          settledCurrency: 'USD',
          tenderCurrency: 'CDF',
          settledCents: 3000,
        ),
      ];

      final tenders = settlement.tendersFor(lines);

      expect(tenders, hasLength(1));
      expect(tenders.single.amountInCents, 22400000); // 224 000 FC
      expect(tenders.single.currency, 'CDF');
      expect(tenders.single.pivotCurrency, 'USD');
    });

    test('un même frais réglé en deux monnaies fait deux lignes — les unités '
        'diffèrent', () {
      final settlement = _settlement();
      final lines = [
        settlement.fromSettled(
          settledCurrency: 'USD',
          tenderCurrency: 'CDF',
          settledCents: 3000,
        ),
        settlement.fromSettled(
          settledCurrency: 'USD',
          tenderCurrency: 'USD',
          settledCents: 2000,
        ),
      ];

      final tenders = settlement.tendersFor(lines);

      expect(tenders.map((t) => t.currency), ['CDF', 'USD']);
      expect(
        TenderComposition.check(
          allocations: settlement.settledBag(lines).entries,
          tenders: tenders,
        ),
        isNull,
        reason:
            'une créance réglée moitié en francs moitié en dollars reste '
            'auditable : c’est côté créance que la somme se vérifie',
      );
    });

    test('les sacs disent chacun leur unité, et ne se mélangent pas', () {
      final settlement = _settlement();
      final lines = [
        settlement.fromSettled(
          settledCurrency: 'USD',
          tenderCurrency: 'CDF',
          settledCents: 5000,
        ),
        settlement.fromSettled(
          settledCurrency: 'CDF',
          tenderCurrency: 'CDF',
          settledCents: 9000000,
        ),
      ];

      expect(settlement.settledBag(lines).currencies, ['CDF', 'USD']);
      expect(settlement.tenderBag(lines).currencies, ['CDF']);
      expect(
        settlement.tenderBag(lines).entries.single,
        Money.parse(23000000, 'CDF'),
        reason: '140 000 FC convertis + 90 000 FC réglés en francs',
      );
    });

    test('la monnaie à rendre se compte à part, jamais dans le tiroir', () {
      final settlement = _settlement();
      final line = settlement.fromTender(
        settledCurrency: 'USD',
        tenderCurrency: 'CDF',
        tenderedCents: 5000000,
      );

      expect(settlement.changeBag([line]).entries.single.amountInCents, 2000);
      expect(
        settlement.tenderBag([line]).entries.single.amountInCents,
        4998000,
      );
    });
  });

  group('le taux corrigé, par paire', () {
    test('le référentiel décide tant que rien n’est corrigé', () {
      expect(_settlement().rateFor('USD', 'CDF')?.rateMicros, _taux2800);
    });

    test('un taux corrigé ne vaut que pour SA paire', () {
      final settlement = _settlement(
        overrides: {TenderSettlement.pairKey('USD', 'CDF'): 3000000000},
      );

      expect(settlement.rateFor('USD', 'CDF')?.rateMicros, 3000000000);
      expect(
        settlement.referenceRateFor('USD', 'CDF')?.rateMicros,
        _taux2800,
        reason:
            'le taux de l’école reste lisible : c’est le second terme du '
            'contrôle de divergence',
      );
    });

    test('au-delà de la bande de l’école, on signale — sans rien bloquer', () {
      // 2 % de bande : 2 800 → 2 856 passe, 3 000 non.
      expect(
        _settlement(
          overrides: {TenderSettlement.pairKey('USD', 'CDF'): 2850000000},
        ).divergesFor('USD', 'CDF'),
        isFalse,
      );
      expect(
        _settlement(
          overrides: {TenderSettlement.pairKey('USD', 'CDF'): 3000000000},
        ).divergesFor('USD', 'CDF'),
        isTrue,
      );
    });

    test('un taux corrigé à zéro est ignoré, jamais appliqué', () {
      final settlement = _settlement(
        overrides: {TenderSettlement.pairKey('USD', 'CDF'): 0},
      );

      expect(settlement.rateFor('USD', 'CDF')?.rateMicros, _taux2800);
      expect(settlement.divergesFor('USD', 'CDF'), isFalse);
    });
  });
}
