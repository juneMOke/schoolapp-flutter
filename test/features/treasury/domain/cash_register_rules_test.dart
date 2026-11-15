import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_register_rules.dart';

import '../treasury_fixtures.dart';

void main() {
  group('availableCurrencies — une caisse par devise (R13)', () {
    test('aucune caisse : les deux devises', () {
      expect(CashRegisterRules.availableCurrencies(const []), [
        TreasuryCurrency.usd,
        TreasuryCurrency.cdf,
      ]);
    });

    test('la caisse USD existe : seul le franc reste', () {
      expect(CashRegisterRules.availableCurrencies([usdRegister]), [
        TreasuryCurrency.cdf,
      ]);
      expect(
        CashRegisterRules.canCreateRegister(TreasuryCurrency.usd, [
          usdRegister,
        ]),
        isFalse,
      );
    });

    test('les deux existent : plus rien à créer', () {
      expect(
        CashRegisterRules.availableCurrencies([usdRegister, cdfRegister]),
        isEmpty,
      );
    });
  });

  test('nom par défaut et doublon insensible à la casse', () {
    expect(CashRegisterRules.defaultName(TreasuryCurrency.cdf), 'Caisse CDF');
    expect(
      CashRegisterRules.isDuplicateName('  caisse usd ', [usdRegister]),
      isTrue,
    );
    expect(
      CashRegisterRules.isDuplicateName('Caisse 2', [usdRegister]),
      isFalse,
    );
    expect(CashRegisterRules.isDuplicateName('   ', [usdRegister]), isFalse);
  });

  group('canAdjust (R14)', () {
    bool can({
      TreasuryCurrency currency = TreasuryCurrency.usd,
      int current = 482000,
      int? next = 490000,
      String reason = 'Recomptage',
      bool closedToday = false,
    }) => CashRegisterRules.canAdjust(
      currency: currency,
      currentInCents: current,
      newAmountInCents: next,
      reason: reason,
      closedToday: closedToday,
    );

    test('un nouveau montant, un motif, une caisse ouverte : oui', () {
      expect(can(), isTrue);
    });

    test('ramener la caisse à 0 est un ajustement valable', () {
      expect(can(next: 0), isTrue);
    });

    test('même montant que l actuel : non', () {
      expect(can(next: 482000), isFalse);
    });

    test('motif de 4 caractères après trim : non ; 5 : oui', () {
      expect(can(reason: '  abcd   '), isFalse);
      expect(can(reason: ' abcde '), isTrue);
    });

    test('caisse clôturée aujourd hui : non', () {
      expect(can(closedToday: true), isFalse);
    });

    test('montant illisible : non', () {
      expect(can(next: null), isFalse);
    });

    test('des centimes de franc : non ; des francs entiers : oui', () {
      expect(
        can(currency: TreasuryCurrency.cdf, current: 0, next: 150050),
        isFalse,
      );
      expect(
        can(currency: TreasuryCurrency.cdf, current: 0, next: 150000),
        isTrue,
      );
    });
  });

  test('« Nouvelle » pendant 7 jours après la mise en service', () {
    expect(
      CashRegisterRules.isNew(cdfRegister, DateTime.utc(2026, 10, 26, 7)),
      isTrue,
    );
    expect(
      CashRegisterRules.isNew(cdfRegister, DateTime.utc(2026, 10, 27, 7)),
      isFalse,
    );
  });
}
