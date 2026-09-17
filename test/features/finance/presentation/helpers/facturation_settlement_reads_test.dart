import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_group_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_settlement_reads.dart';

/// Lot R4 — les lectures du règlement, sorties de la page.
///
/// ⚠️ **Tout est asséré en CENTS, jamais sur une écriture.** Le formatage a ses
/// propres tests, et trois échecs de ce chantier sont venus de paris dessus.
final _taux = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2000000000,
  effectiveFrom: DateTime.utc(2026, 1, 1),
  divergenceBandBp: 200,
);

TenderSettlement _reglement({List<ExchangeRate> rates = const []}) =>
    TenderSettlement(rates: rates, at: DateTime.utc(2026, 9, 16, 8));

StudentCharge _charge({String id = 'sc-1', int cents = 3000}) => StudentCharge(
  id: id,
  studentId: 'stu-1',
  academicYearId: 'ay-1',
  schoolLevelId: 'lvl-1',
  schoolLevelGroupId: 'grp-1',
  feeTariffId: 'tar-$id',
  feeCode: 'MINERVAL',
  label: 'Minerval',
  expectedAmountInCents: cents.toDouble(),
  amountPaidInCents: 0,
  currency: 'USD',
  status: StudentChargeStatus.due,
);

/// Une tranche cochée qui impute [impute] cents.
FacturationChargeEntry _entree({int cents = 3000, int impute = 3000}) {
  final entry = FacturationChargeEntry(_charge(cents: cents))..selected = true;
  entry.controller.text = (impute / 100).toStringAsFixed(2);
  return entry;
}

void main() {
  group('lineOf', () {
    test('sans conversion, le comptoir vaut l\'imputation', () {
      final line = lineOf(_reglement(), _entree(impute: 3000));

      expect(line.settledCents, 3000);
      expect(line.tenderCents, 3000);
      expect(line.changeCents, 0);
    });

    test(
      'quand le comptoir est source, l\'imputation se déduit vers le bas',
      () {
        // Le parent pose 40 000 FC ; à 2 000,00 cela éteint 20,00 $.
        final entry = _entree()
          ..tenderCurrency = 'CDF'
          ..tenderBecomesSource();
        entry.tenderController.text = '40000';

        final line = lineOf(_reglement(rates: [_taux]), entry);

        expect(line.settledCents, 2000);
      },
    );

    test('ÉCRÊTE : poser plus que le restant ne l\'impute pas au-delà', () {
      // 30,00 $ dus. Le parent pose 999 999 FC, soit ~500 $ au taux du jour.
      final entry = _entree()
        ..tenderCurrency = 'CDF'
        ..tenderBecomesSource();
      entry.tenderController.text = '999999';

      final line = lineOf(_reglement(rates: [_taux]), entry);

      // L'imputation reste au restant, et le surplus repart avec le parent.
      expect(line.settledCents, 3000);
      expect(line.changeCents, greaterThan(0));
    });
  });

  group('linesOf', () {
    test('écarte une ligne non cochée', () {
      final entry = _entree()..selected = false;

      expect(linesOf(_reglement(), [entry]), isEmpty);
    });

    test('écarte une ligne cochée mais vide des DEUX côtés', () {
      final entry = _entree(impute: 0);
      entry.controller.text = '';

      expect(linesOf(_reglement(), [entry]), isEmpty);
    });

    test('retient une ligne qui ne porte QUE du comptoir', () {
      // Le parent a posé des billets sans qu'on ait encore tapé l'imputation :
      // la ligne existe, elle ne doit pas disparaître du total.
      final entry = _entree(impute: 0)
        ..tenderCurrency = 'CDF'
        ..tenderBecomesSource();
      entry.controller.text = '';
      entry.tenderController.text = '40000';

      expect(linesOf(_reglement(rates: [_taux]), [entry]), hasLength(1));
    });
  });

  group('les sacs de devises', () {
    test('séparent les devises plutôt que de les sommer', () {
      final bag = settledBagOf(_reglement(), [_entree(impute: 3000)]);

      expect(bag.entries, hasLength(1));
      expect(bag.entries.single.amountInCents, 3000);
      expect(bag.entries.single.currency, 'USD');
    });

    test('le sac du tiroir compte la devise REÇUE', () {
      final entry = _entree()..tenderCurrency = 'CDF';

      final bag = tenderBagOf(_reglement(rates: [_taux]), [entry]);

      expect(bag.entries.single.currency, 'CDF');
    });
  });

  group('hasConversion', () {
    test('est faux quand on règle dans la devise de la créance', () {
      // Régler en dollars des créances en dollars n'est pas une conversion.
      expect(hasConversion(_reglement(), [_entree()]), isFalse);
    });

    test('est vrai dès qu\'une ligne convertit', () {
      final entry = _entree()..tenderCurrency = 'CDF';

      expect(hasConversion(_reglement(rates: [_taux]), [entry]), isTrue);
    });
  });

  group('groupTenderCents', () {
    FacturationChargeGroupEntry groupe(List<FacturationChargeEntry> tranches) =>
        FacturationChargeGroupEntry(
          feeCode: 'MINERVAL',
          currency: 'USD',
          tranches: tranches,
        );

    test('vaut zéro quand la nature ne convertit pas', () {
      expect(groupTenderCents(_reglement(), groupe([_entree()])), 0);
    });

    test('somme ce que ses tranches font entrer au tiroir', () {
      final group = groupe([_entree(impute: 3000), _entree(impute: 3000)])
        ..groupCommands();
      group.setTenderCurrency('CDF');

      // 2 × 30,00 $ à 2 000,00 = 2 × 60 000 FC.
      expect(groupTenderCents(_reglement(rates: [_taux]), group), 12000000);
    });
  });

  group('les gardes', () {
    test('l\'invariant perçu/imputé ne se prononce pas sur du vide', () {
      expect(tenderInvariantBroken(_reglement(), const []), isFalse);
    });

    test('« aucun taux » est faux tant qu\'aucun frais n\'est coché', () {
      // Sans frais retenu il n'y a pas encore de question à poser : une mention
      // sur un formulaire vide serait du bruit.
      final entry = _entree()..selected = false;

      expect(hasNoConvertibleCharge(_reglement(), [entry]), isFalse);
    });

    test(
      '« aucun taux » est vrai quand un frais est coché sans devise sortante',
      () {
        expect(hasNoConvertibleCharge(_reglement(), [_entree()]), isTrue);
      },
    );

    test('« aucun taux » redevient faux dès qu\'une devise est proposable', () {
      expect(
        hasNoConvertibleCharge(_reglement(rates: [_taux]), [_entree()]),
        isFalse,
      );
    });
  });
}
