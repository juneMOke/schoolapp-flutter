import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_collect_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// Lot R1 — les libellés sortis de la page.
///
/// ⚠️ **Ces tests n'assèrent pas l'écriture des nombres.** Le formatage a sa
/// propre implémentation, testée ailleurs, et trois échecs de ce chantier sont
/// venus de paris sur `60000` contre `60000,00`. Ce qui est éprouvé ici est le
/// COMPORTEMENT : quand la fonction rend `null`, sur quoi elle se replie, et que
/// les trois surfaces qui montrent un taux montrent bien **le même**.
final _taux = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 1666670000,
  effectiveFrom: DateTime.utc(2026, 1, 1),
  divergenceBandBp: 200,
);

SettlementLine _ligne({
  ExchangeRate? rate,
  String settled = 'USD',
  String tender = 'CDF',
  int settledCents = 3000,
  int tenderCents = 5000010,
  int changeCents = 0,
}) => SettlementLine(
  settledCurrency: settled,
  tenderCurrency: tender,
  rate: rate,
  settledCents: settledCents,
  tenderCents: tenderCents,
  changeCents: changeCents,
);

void main() {
  final l10n = AppLocalizationsFr();

  group('rateLabel', () {
    test('est la MÊME écriture pour la ligne et pour le versement', () {
      // C'est tout l'objet du lot : l'expression était écrite trois fois. Si
      // elles divergent un jour, le parent qui recompte au guichet ne retombe
      // pas sur son total.
      final direct = rateLabel(_taux);

      expect(lineRateLabel(_ligne(rate: _taux)), direct);
      expect(singleRateLabel([_ligne(rate: _taux)]), direct);
    });

    test('nomme les deux devises', () {
      final rendu = rateLabel(_taux);

      expect(rendu, contains('FC'));
      expect(rendu, contains('/'));
    });
  });

  group('lineRateLabel', () {
    test('rend null quand la ligne ne convertit pas', () {
      expect(lineRateLabel(_ligne()), isNull);
    });
  });

  group('singleRateLabel', () {
    test('rend null sans aucun taux', () {
      expect(singleRateLabel([_ligne(), _ligne()]), isNull);
    });

    test('rend le taux quand toutes les lignes portent le même', () {
      expect(
        singleRateLabel([_ligne(rate: _taux), _ligne(rate: _taux)]),
        rateLabel(_taux),
      );
    });

    test('rend null dès qu\'il y en a DEUX différents', () {
      // Deux taux sur une seule ligne de récapitulatif se liraient comme un
      // seul.
      final autre = ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        rateMicros: 2000000000,
        effectiveFrom: DateTime.utc(2026, 9, 15),
        divergenceBandBp: 200,
      );

      expect(
        singleRateLabel([_ligne(rate: _taux), _ligne(rate: autre)]),
        isNull,
      );
    });
  });

  group('tenderLabel', () {
    test('rend null quand le tiroir ne garde rien', () {
      expect(tenderLabel(0, 'CDF'), isNull);
      expect(tenderLabel(-1, 'CDF'), isNull);
    });

    test('rend un montant dès qu\'il y a quelque chose à annoncer', () {
      expect(tenderLabel(5000010, 'CDF'), isNotNull);
    });
  });

  group('tenderLabelOf', () {
    test('rend null quand la ligne ne convertit pas', () {
      // Régler en dollars une créance en dollars n'est pas une conversion : il
      // n'y a pas de second montant à montrer.
      expect(tenderLabelOf(_ligne(tender: 'USD')), isNull);
    });

    test('rend le montant reçu quand elle convertit', () {
      expect(tenderLabelOf(_ligne(rate: _taux)), isNotNull);
    });
  });

  group('changeLabel', () {
    test('rend null quand la conversion tombe juste', () {
      expect(changeLabel(0, 'CDF', l10n), isNull);
      expect(changeLabel(-5, 'CDF', l10n), isNull);
    });

    test('annonce ce qui repart avec le parent', () {
      expect(changeLabel(2000, 'CDF', l10n), isNotNull);
    });

    test('une LIGNE porte déjà sa monnaie à rendre, et dit la même phrase', () {
      // Ligne et nature calculent leur excédent différemment — l'une le tient
      // dans `changeCents`, l'autre le déduit. La phrase, elle, doit être la
      // même : c'est tout l'objet de la fonction partagée.
      expect(
        lineChangeLabel(_ligne(rate: _taux, changeCents: 2000), l10n),
        changeLabel(2000, 'CDF', l10n),
      );
    });

    test('une ligne dont la conversion tombe juste ne rend rien', () {
      expect(lineChangeLabel(_ligne(rate: _taux), l10n), isNull);
    });
  });

  group('bagLabel', () {
    test('sépare les devises, il ne les somme jamais', () {
      final rendu = bagLabel(
        MoneyBag.of(const [Money(42500, 'USD'), Money(9000000, 'CDF')]),
      );

      expect(rendu, contains('·'));
    });
  });

  group('studentFullName', () {
    FacturationCreatePaymentIntent intent({
      String lastName = 'Makela',
      String surname = 'Mbuyi',
      String firstName = 'Kevin',
      String levelName = '5e A',
      String levelGroupName = 'Primaire',
    }) => FacturationCreatePaymentIntent(
      studentId: 'stu-1',
      academicYearId: 'ay-1',
      firstName: firstName,
      lastName: lastName,
      surname: surname,
      levelName: levelName,
      levelGroupName: levelGroupName,
      studentCharges: const [],
    );

    test('compose nom, post-nom et prénom', () {
      expect(studentFullName(intent(), l10n), 'Makela Mbuyi Kevin');
    });

    test('escamote les parties vides sans laisser d\'espace double', () {
      expect(studentFullName(intent(surname: '  '), l10n), 'Makela Kevin');
    });

    test('se replie sur « inconnu » plutôt que sur une chaîne vide', () {
      expect(
        studentFullName(intent(lastName: '', surname: '', firstName: ''), l10n),
        l10n.facturationDetailUnknownValue,
      );
    });

    test('préfère le niveau, puis le cycle, puis « inconnu »', () {
      expect(classLabel(intent(), l10n), '5e A');
      expect(classLabel(intent(levelName: '   '), l10n), 'Primaire');
      expect(
        classLabel(intent(levelName: '', levelGroupName: ''), l10n),
        l10n.facturationDetailUnknownValue,
      );
    });
  });
}
