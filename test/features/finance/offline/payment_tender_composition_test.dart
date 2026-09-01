import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_tender_composition.dart';

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
      final tenders = PaymentTenderComposition.identityFor(const [
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
      final tenders = PaymentTenderComposition.identityFor(const [
        Money(3000, 'USD'),
        Money(9000000, 'CDF'),
      ]);

      expect(tenders.map((t) => t.currency), ['CDF', 'USD']);
      expect(tenders.map((t) => t.amountInCents), [9000000, 3000]);
    });

    test('les devises sont normalisées avant regroupement', () {
      final tenders = PaymentTenderComposition.identityFor([
        Money.parse(3000, ' usd '),
        const Money(1500, 'USD'),
      ]);

      expect(tenders, hasLength(1));
      expect(tenders.single.amountInCents, 4500);
    });

    test('l’identité satisfait toujours l’invariant', () {
      const allocations = [Money(3000, 'USD'), Money(9000000, 'CDF')];
      expect(
        PaymentTenderComposition.check(
          allocations: allocations,
          tenders: PaymentTenderComposition.identityFor(allocations),
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
      final violation = PaymentTenderComposition.check(
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

    test('un franc de trop passe, deux ne passent pas', () {
      TenderInvariantViolation? verdict(int received) =>
          PaymentTenderComposition.check(
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

      // Attendu : 5 000 010. La tolérance vaut 1 FC = 100 centimes.
      expect(verdict(5000110), isNull);
      expect(verdict(5000111), isNotNull);
    });

    test(
      'la tolérance du dollar est cent fois plus fine que celle du franc',
      () {
        // 1 cent de dollar, contre 1 franc entier : la tolérance se lit sur la
        // devise REÇUE, pas sur celle de la créance.
        final violation = PaymentTenderComposition.check(
          allocations: const [Money(5000000, 'CDF')],
          tenders: const [
            TenderDraft(
              // 50 000 FC à 0,0006 $/FC = 30,00 $ ; on en reçoit 30,02 $.
              amountInCents: 3002,
              currency: 'USD',
              rateMicros: 600,
              pivotCurrency: 'CDF',
            ),
          ],
        );

        expect(violation, isNotNull);
      },
    );

    test('la fuite du taux est refusée', () {
      // 100 000 FC encaissés pour une créance de 50 $ quand le taux du jour en
      // vaut 145 000 : la créance s'éteint, la caisse est cohérente, et
      // 45 000 FC sont partis. C'est le seul risque NOUVEAU de la V2.
      final violation = PaymentTenderComposition.check(
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
        final violation = PaymentTenderComposition.check(
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
      final violation = PaymentTenderComposition.check(
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
      final violation = PaymentTenderComposition.check(
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
      final violation = PaymentTenderComposition.check(
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
        final violation = PaymentTenderComposition.check(
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
      final violation = PaymentTenderComposition.check(
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
        PaymentTenderComposition.check(
          allocations: const [],
          tenders: const [],
        ),
        isNull,
      );
    });
  });
}
