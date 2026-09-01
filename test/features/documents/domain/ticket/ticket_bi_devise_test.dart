import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_text_layout.dart';

/// Le ticket quand un franc règle un dollar.
///
/// Avant ce lot, « Montant reçu » était alimenté par les IMPUTATIONS : le
/// papier remis à un parent qui vient de poser 50 000 FC annonçait « 30,00 $ ».
/// Contrairement au reçu scellé, dont l'assertion serveur refuse de rendre le
/// document, celui-ci s'imprimait — faux.
const int _taux166667 = 1666670000;

const _labels = TicketLabels(
  documentTitle: 'Ticket de perception',
  provisionalBanner: 'Provisoire',
  referenceLabel: 'Réf.',
  cashierLabel: 'Caissier :',
  studentLabel: 'Élève :',
  matriculationLabel: 'Matricule :',
  classroomLabel: 'Classe :',
  amountReceivedLabel: 'Montant reçu',
  rateLabel: 'Taux',
  derivedAmountPrefix: 'soit',
  allocationsLabel: 'Répartition',
  advanceLabel: 'Avance (non imputée)',
  balanceLabel: 'Solde',
  balanceReservation: 'sous réserve de synchronisation',
  keepTicketNotice: 'Conservez ce ticket.',
);

TicketReceiptModel _model({
  required List<TicketTenderLine> tenders,
  required List<TicketAllocationLine> allocations,
  MoneyBag? remainingBalance,
}) => TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  studentFullName: 'MAKELA Kevin',
  provisionalReference: 'PROV-A1B2C3-9F8E7D6C',
  paidAt: DateTime(2026, 9, 1, 9, 30),
  cashierFullName: 'Sarah Ngalula',
  tenders: tenders,
  allocations: allocations,
  remainingBalance: remainingBalance,
  labels: _labels,
);

String _flat(List<String> lines) => lines.join('\n');

void main() {
  group('le montant reçu vient du tiroir', () {
    test(
      'un règlement en francs sur une créance en dollars s’imprime en francs',
      () {
        final model = _model(
          tenders: const [
            TicketTenderLine(
              amountInCents: 5000000,
              currency: 'CDF',
              rateMicros: _taux166667,
              pivotCurrency: 'USD',
            ),
          ],
          allocations: const [
            TicketAllocationLine(
              label: 'Minerval — tranche 1',
              amountInCents: 3000,
              currency: 'USD',
            ),
          ],
        );

        expect(
          model.amountReceived,
          MoneyBag.of(const [Money(5000000, 'CDF')]),
        );

        final papier = _flat(TicketTextLayout.render(model));
        expect(papier, contains('Montant reçu'));
        expect(papier, contains('50 000 FC'));
        // Et surtout : le papier n'annonce PAS de dollars reçus.
        expect(
          papier,
          isNot(contains('Montant reçu                       30,00 \$')),
        );
      },
    );

    test('l’imputation, elle, reste en devise de créance', () {
      final papier = _flat(
        TicketTextLayout.render(
          _model(
            tenders: const [
              TicketTenderLine(
                amountInCents: 5000000,
                currency: 'CDF',
                rateMicros: _taux166667,
                pivotCurrency: 'USD',
              ),
            ],
            allocations: const [
              TicketAllocationLine(
                label: 'Minerval — tranche 1',
                amountInCents: 3000,
                currency: 'USD',
              ),
            ],
          ),
        ),
      );

      expect(papier, contains('Minerval'));
      expect(papier, contains(r'30,00 $'));
    });
  });

  group('le taux', () {
    test('s’imprime quand les unités divergent', () {
      final papier = _flat(
        TicketTextLayout.render(
          _model(
            tenders: const [
              TicketTenderLine(
                amountInCents: 5000000,
                currency: 'CDF',
                rateMicros: _taux166667,
                pivotCurrency: 'USD',
              ),
            ],
            allocations: const [
              TicketAllocationLine(
                label: 'Minerval',
                amountInCents: 3000,
                currency: 'USD',
              ),
            ],
          ),
        ),
      );

      expect(papier, contains('Taux'));
      // Deux décimales, celles qui sont stockées : le parent recompte.
      expect(papier, contains('1 666,67'));
      expect(papier, contains(r'FC / $'));
    });

    test('ne s’imprime pas sur un règlement ordinaire', () {
      // Un « 1,00 » ferait chercher au parent ce qui a été converti.
      final papier = _flat(
        TicketTextLayout.render(
          _model(
            tenders: TicketTenderLine.identityFrom(
              MoneyBag.of(const [Money(150000, 'CDF')]),
            ),
            allocations: const [
              TicketAllocationLine(
                label: 'Frais scolaires',
                amountInCents: 150000,
                currency: 'CDF',
              ),
            ],
          ),
        ),
      );

      expect(papier, isNot(contains('Taux')));
    });

    test('sur 32 colonnes, la paire cède la place au nombre', () {
      // 58 mm : « Taux » plus « 1 666,67 FC / $ » ne tient pas.
      final papier = _flat(
        TicketTextLayout.render(
          _model(
            tenders: const [
              TicketTenderLine(
                amountInCents: 5000000,
                currency: 'CDF',
                rateMicros: _taux166667,
                pivotCurrency: 'USD',
              ),
            ],
            allocations: const [
              TicketAllocationLine(
                label: 'Minerval',
                amountInCents: 3000,
                currency: 'USD',
              ),
            ],
          ),
          columns: 32,
        ),
      );

      expect(papier, contains('1 666,67 FC'));
      expect(papier, isNot(contains(r'FC / $')));
      // Aucune ligne ne déborde de la largeur du papier.
      for (final ligne in TicketTextLayout.render(
        _model(
          tenders: const [
            TicketTenderLine(
              amountInCents: 5000000,
              currency: 'CDF',
              rateMicros: _taux166667,
              pivotCurrency: 'USD',
            ),
          ],
          allocations: const [
            TicketAllocationLine(
              label: 'Minerval — tranche 1 sur sept',
              amountInCents: 3000,
              currency: 'USD',
            ),
          ],
        ),
        columns: 32,
      )) {
        expect(ligne.length, lessThanOrEqualTo(32), reason: 'ligne : "$ligne"');
      }
    });
  });

  group('la répartition dérivée', () {
    test('chaque poste porte sa valeur en devise reçue', () {
      final papier = _flat(
        TicketTextLayout.render(
          _model(
            tenders: const [
              TicketTenderLine(
                amountInCents: 11200000,
                currency: 'CDF',
                rateMicros: 1244440000,
                pivotCurrency: 'USD',
              ),
            ],
            allocations: const [
              TicketAllocationLine(
                label: 'Frais 1',
                amountInCents: 4000,
                currency: 'USD',
              ),
              TicketAllocationLine(
                label: 'Frais 2',
                amountInCents: 5000,
                currency: 'USD',
              ),
            ],
          ),
        ),
      );

      expect(papier, contains('soit'));
      // 40,00 $ à 1 244,44 = 49 777,60 FC ; la ligne s'écrit avec ses centimes
      // réels, que la règle d'écriture du franc n'escamote jamais.
      expect(papier, contains('49 777,60 FC'));
    });

    test('la dernière ligne absorbe le résidu : la colonne somme au perçu', () {
      final model = _model(
        tenders: const [
          TicketTenderLine(
            amountInCents: 11200000,
            currency: 'CDF',
            rateMicros: 1244440000,
            pivotCurrency: 'USD',
          ),
        ],
        allocations: const [
          TicketAllocationLine(
            label: 'Frais 1',
            amountInCents: 4000,
            currency: 'USD',
          ),
          TicketAllocationLine(
            label: 'Frais 2',
            amountInCents: 5000,
            currency: 'USD',
          ),
        ],
      );

      final derivees = model.allocations
          .map((a) => model.derivedAmountOf(a)!.amountInCents)
          .fold<int>(0, (sum, cents) => sum + cents);

      // Sans absorption : 49 777,60 + 62 222,00 = 111 999,60, et le parent qui
      // additionne trouve un écart de 40 centimes que rien n'explique.
      expect(derivees, 11200000);
    });

    test('aucune dérivée sur un règlement ordinaire', () {
      final model = _model(
        tenders: TicketTenderLine.identityFrom(
          MoneyBag.of(const [Money(150000, 'CDF')]),
        ),
        allocations: const [
          TicketAllocationLine(
            label: 'Frais scolaires',
            amountInCents: 150000,
            currency: 'CDF',
          ),
        ],
      );

      expect(model.derivedAmountOf(model.allocations.single), isNull);
      expect(_flat(TicketTextLayout.render(model)), isNot(contains('soit')));
    });

    test('deux règlements de devises différentes sur un même pivot n’en '
        'produisent aucune', () {
      // Le modèle l'autorise, la saisie ne le produit pas. Imprimer l'une des
      // deux conversions ferait recompter le parent sur un chiffre qui
      // n'explique que la moitié de la ligne.
      final model = _model(
        tenders: const [
          TicketTenderLine(
            amountInCents: 2500000,
            currency: 'CDF',
            rateMicros: _taux166667,
            pivotCurrency: 'USD',
          ),
          TicketTenderLine(
            amountInCents: 1500,
            currency: 'EUR',
            rateMicros: 900000,
            pivotCurrency: 'USD',
          ),
        ],
        allocations: const [
          TicketAllocationLine(
            label: 'Minerval',
            amountInCents: 3000,
            currency: 'USD',
          ),
        ],
      );

      expect(model.derivedAmountOf(model.allocations.single), isNull);
    });
  });

  group('l’avance', () {
    test('se dit dans la monnaie posée sur le comptoir', () {
      // 60 000 FC reçus contre 30,00 $ imputés au taux de 1 666,67 : il reste
      // 9 999,90 FC dans le tiroir — et surtout pas « 6,00 $ ».
      final model = _model(
        tenders: const [
          TicketTenderLine(
            amountInCents: 6000000,
            currency: 'CDF',
            rateMicros: _taux166667,
            pivotCurrency: 'USD',
          ),
        ],
        allocations: const [
          TicketAllocationLine(
            label: 'Minerval',
            amountInCents: 3000,
            currency: 'USD',
          ),
        ],
      );

      expect(model.advance.entries.single.currency, 'CDF');
      expect(model.advance.entries.single.amountInCents, 999990);
      expect(_flat(TicketTextLayout.render(model)), contains('Avance'));
    });

    test('un règlement juste n’en laisse aucune', () {
      final model = _model(
        tenders: const [
          TicketTenderLine(
            amountInCents: 5000010,
            currency: 'CDF',
            rateMicros: _taux166667,
            pivotCurrency: 'USD',
          ),
        ],
        allocations: const [
          TicketAllocationLine(
            label: 'Minerval',
            amountInCents: 3000,
            currency: 'USD',
          ),
        ],
      );

      expect(model.advance.isEmpty, isTrue);
    });
  });

  test('un versement mixte imprime une ligne de perçu par unité', () {
    final papier = _flat(
      TicketTextLayout.render(
        _model(
          tenders: const [
            TicketTenderLine(
              amountInCents: 5000000,
              currency: 'CDF',
              rateMicros: _taux166667,
              pivotCurrency: 'USD',
            ),
            TicketTenderLine(
              amountInCents: 9000000,
              currency: 'CDF',
              pivotCurrency: 'CDF',
            ),
          ],
          allocations: const [
            TicketAllocationLine(
              label: 'Minerval',
              amountInCents: 3000,
              currency: 'USD',
            ),
            TicketAllocationLine(
              label: 'Visite médicale',
              amountInCents: 9000000,
              currency: 'CDF',
            ),
          ],
        ),
      ),
    );

    // Les deux règlements sont en francs : le sac les groupe, et le tiroir a
    // bien vu 140 000 FC.
    expect(papier, contains('140 000 FC'));
    // Un seul taux imprimé : celui du pivot qui en a un.
    expect('Taux'.allMatches(papier).length, 1);
  });
}
