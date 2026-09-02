import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';

/// L'invariant qui rend le couple perçu/imputé auditable.
///
/// Ce n'est PAS la garde qui compare `amounts` aux imputations : celle-là
/// compare de l'imputé à de l'imputé et reste juste. Celle-ci est la seconde, et
/// elle n'existait nulle part — sans elle, encaisser 100 000 FC pour une créance
/// de 50 $ quand le taux du jour en vaut 145 000 laisse la créance éteinte, la
/// caisse cohérente, et 45 000 FC partis.
const int _taux166667 = 1666670000;

void main() {
  group('identityFor — le cas courant ne coûte aucune arithmétique', () {
    test('une devise, un règlement, taux 1', () {
      final tenders = TenderComposition.identityFor(const [
        Money(3000, 'USD'),
        Money(1500, 'USD'),
      ]);

      expect(tenders, hasLength(1));
      expect(tenders.single.amountInCents, 4500);
      expect(tenders.single.currency, 'USD');
      expect(tenders.single.pivotCurrency, 'USD');
      expect(tenders.single.rateMicros, 1000000);
    });

    test('deux devises de créance font deux lignes, jamais une somme', () {
      final tenders = TenderComposition.identityFor(const [
        Money(3000, 'USD'),
        Money(9000000, 'CDF'),
      ]);

      expect(tenders.map((t) => t.currency), ['CDF', 'USD']);
      expect(tenders.map((t) => t.amountInCents), [9000000, 3000]);
    });

    test('les devises sont normalisées avant regroupement', () {
      final tenders = TenderComposition.identityFor([
        Money.parse(3000, ' usd '),
        const Money(1500, 'USD'),
      ]);

      expect(tenders, hasLength(1));
      expect(tenders.single.amountInCents, 4500);
    });

    test('l’identité satisfait toujours l’invariant', () {
      const allocations = [Money(3000, 'USD'), Money(9000000, 'CDF')];
      expect(
        TenderComposition.check(
          allocations: allocations,
          tenders: TenderComposition.identityFor(allocations),
        ),
        isNull,
      );
    });
  });

  group('check — l’invariant du taux', () {
    test('30,00 \$ réglés par 50 000 FC : accepté', () {
      // 3000 × 1 666,67 = 5 000 010 centimes de franc pour 5 000 000 reçus :
      // 10 centimes d'écart, sous l'unité d'affichage du franc. Refuser cet
      // écart, c'est refuser un versement juste.
      final violation = TenderComposition.check(
        allocations: const [Money(3000, 'USD')],
        tenders: const [
          TenderDraft(
            amountInCents: 5000000,
            currency: 'CDF',
            rateMicros: _taux166667,
            pivotCurrency: 'USD',
          ),
        ],
      );

      expect(violation, isNull);
    });

    test('l’écart se mesure APRÈS conversion, en centimes de créance', () {
      TenderInvariantViolation? verdict(int received) =>
          TenderComposition.check(
            allocations: const [Money(3000, 'USD')],
            tenders: [
              TenderDraft(
                amountInCents: received,
                currency: 'CDF',
                rateMicros: _taux166667,
                pivotCurrency: 'USD',
              ),
            ],
          );

      // 30,00 \$ dus, soit 50 000,10 FC à 1 666,67. La tolérance vaut
      // `max(1, 100 ÷ 1 666,67)` = **1 centime de dollar** — pas un franc :
      // c'est la règle du serveur, qui compare côté créance.
      //
      // Un franc de trop disparaît donc dans la division (16,67 FC valent un
      // centime) ; il faut deux centimes de dollar d'écart pour être refusé.
      expect(verdict(5000110), isNull);
      expect(verdict(5001678), isNull, reason: 'un centime : admis');
      expect(verdict(5003345), isNotNull, reason: 'deux centimes : refusé');
    });

    test(
      'une créance en FRANCS réglée en dollars admet bien plus qu’un centime',
      () {
        // Le cas que le cahier de recette exerce (P3-37), et celui qu'un
        // centime forfaitaire refuserait à tort : l'unité d'affichage du
        // dollar — un cent — vaut ~2 299 centimes de franc au taux courant.
        // C'est là que le plancher `max(1, …)` ne sert PAS, et que la formule
        // du serveur diverge d'une tolérance fixe.
        final violation = TenderComposition.check(
          allocations: const [Money(9000000, 'CDF')],
          tenders: const [
            TenderDraft(
              // 90 000 FC à 0,000435 \$/FC = 39,15 \$ ; le comptoir en compte
              // 39,16 — un cent de plus, soit ~23 FC une fois reconverti.
              amountInCents: 3916,
              currency: 'USD',
              rateMicros: 435,
              pivotCurrency: 'CDF',
            ),
          ],
        );

        expect(
          violation,
          isNull,
          reason:
              'le serveur l’accepte : refuser ici éteindrait le CTA sur un '
              'versement parfaitement valide',
        );
      },
    );

    test('un écart qui dépasse la tolérance de SA ligne est refusé', () {
      // 50 000 FC dus à 0,0006 \$/FC = 30,00 \$ ; on en reçoit 30,60. La
      // tolérance vaut `max(1, 1 ÷ 0,0006)` = 1 666 centimes de franc, et
      // l'écart reconverti en vaut 100 000 : soixante fois trop.
      final violation = TenderComposition.check(
        allocations: const [Money(5000000, 'CDF')],
        tenders: const [
          TenderDraft(
            amountInCents: 3060,
            currency: 'USD',
            rateMicros: 600,
            pivotCurrency: 'CDF',
          ),
        ],
      );

      expect(violation, isNotNull);
      expect(
        violation.toString(),
        contains('admis'),
        reason:
            'le message porte les deux nombres, comme le 422 du serveur : '
            'l’écart et ce qui était admis',
      );
    });

    test('la fuite du taux est refusée', () {
      // 100 000 FC encaissés pour une créance de 50 $ quand le taux du jour en
      // vaut 145 000 : la créance s'éteint, la caisse est cohérente, et
      // 45 000 FC sont partis. C'est le seul risque NOUVEAU de la V2.
      final violation = TenderComposition.check(
        allocations: const [Money(5000, 'USD')],
        tenders: const [
          TenderDraft(
            amountInCents: 10000000,
            currency: 'CDF',
            rateMicros: 2900000000,
            pivotCurrency: 'USD',
          ),
        ],
      );

      expect(violation, isNotNull);
      expect(violation.toString(), contains('Perçu'));
    });

    test(
      'un versement en deux temps au même taux s’additionne avant l’épreuve',
      () {
        // Une pile de billets posée en deux fois n'est pas une décision : deux
        // lignes de même pivot et de même unité se somment.
        final violation = TenderComposition.check(
          allocations: const [Money(3000, 'USD')],
          tenders: const [
            TenderDraft(
              amountInCents: 4000000,
              currency: 'CDF',
              rateMicros: _taux166667,
              pivotCurrency: 'USD',
            ),
            TenderDraft(
              amountInCents: 1000000,
              currency: 'CDF',
              rateMicros: _taux166667,
              pivotCurrency: 'USD',
            ),
          ],
        );

        expect(violation, isNull);
      },
    );

    test('deux taux pour la même paire sont refusés', () {
      final violation = TenderComposition.check(
        allocations: const [Money(3000, 'USD')],
        tenders: const [
          TenderDraft(
            amountInCents: 2500000,
            currency: 'CDF',
            rateMicros: _taux166667,
            pivotCurrency: 'USD',
          ),
          TenderDraft(
            amountInCents: 2500000,
            currency: 'CDF',
            rateMicros: 1700000000,
            pivotCurrency: 'USD',
          ),
        ],
      );

      expect(violation.toString(), contains('Deux taux'));
    });

    test('une créance imputée sans rien de reçu est refusée', () {
      // De l'argent aurait éteint une dette sans jamais entrer dans le tiroir.
      final violation = TenderComposition.check(
        allocations: const [Money(3000, 'USD'), Money(9000000, 'CDF')],
        tenders: const [
          TenderDraft(
            amountInCents: 3000,
            currency: 'USD',
            pivotCurrency: 'USD',
          ),
        ],
      );

      expect(violation.toString(), contains('CDF'));
    });

    test('un règlement adossé à une créance absente est refusé', () {
      final violation = TenderComposition.check(
        allocations: const [Money(3000, 'USD')],
        tenders: const [
          TenderDraft(
            amountInCents: 9000000,
            currency: 'CDF',
            pivotCurrency: 'CDF',
          ),
        ],
      );

      expect(violation.toString(), contains('imputée nulle part'));
    });

    test('un taux nul ou négatif est refusé', () {
      for (final micros in const [0, -1666670000]) {
        final violation = TenderComposition.check(
          allocations: const [Money(3000, 'USD')],
          tenders: [
            TenderDraft(
              amountInCents: 5000000,
              currency: 'CDF',
              rateMicros: micros,
              pivotCurrency: 'USD',
            ),
          ],
        );
        expect(violation.toString(), contains('Taux de guichet invalide'));
      }
    });

    test('un versement mixte — francs sur une créance en dollars, dollars sur '
        'une créance en dollars — tient pivot par pivot', () {
      final violation = TenderComposition.check(
        allocations: const [Money(3000, 'USD'), Money(9000000, 'CDF')],
        tenders: const [
          TenderDraft(
            amountInCents: 5000000,
            currency: 'CDF',
            rateMicros: _taux166667,
            pivotCurrency: 'USD',
          ),
          TenderDraft(
            amountInCents: 9000000,
            currency: 'CDF',
            pivotCurrency: 'CDF',
          ),
        ],
      );

      expect(violation, isNull);
    });

    test('un versement sans rien à imputer ni rien à recevoir tient', () {
      // Le refus du versement vide appartient à l'appelant, pas à l'invariant.
      expect(
        TenderComposition.check(
          allocations: const [],
          tenders: const [],
        ),
        isNull,
      );
    });
  });
}
