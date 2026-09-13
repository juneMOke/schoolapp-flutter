import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';

final _rate2800 = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2800 * ExchangeRate.scale,
  effectiveFrom: DateTime.utc(2026, 9, 1),
);

Expense _expense(int cents, String currency) => Expense(
  id: '$cents$currency',
  typeId: 't',
  title: 'x',
  amountInCents: cents,
  currency: currency,
  status: ExpenseStatus.paid,
  expenseDate: DateTime(2026, 9, 3),
  clientUpdatedAt: DateTime.utc(2026),
);

void main() {
  group('ExpenseUsdReader', () {
    test('385 000 FC au taux de 2 800 se lisent 137,50 \$', () {
      final reader = ExpenseUsdReader(_rate2800);
      expect(reader.usdCentsOf(const Money(38500000, 'CDF')), 13750);
    });

    test('arrondi au plus proche, jamais la troncature', () {
      // 1 FC = 0,000357 $ → 0 cent ; 5 000 FC = 1,7857 $ → 179 cents.
      expect(
        ExpenseUsdReader(_rate2800).usdCentsOf(const Money(500000, 'CDF')),
        179,
      );
    });

    test('un dollar se lit tel quel, même sans taux', () {
      expect(
        ExpenseUsdReader.withoutRate.usdCentsOf(const Money(14200, 'usd')),
        14200,
      );
    });

    test('sans taux, le franc ne se lit pas — jamais un 1 pour 1 (A5)', () {
      expect(
        ExpenseUsdReader.withoutRate.usdCentsOf(const Money(38500000, 'CDF')),
        isNull,
      );
    });

    test('un sac qui ne se lit pas entièrement ne rend aucun total', () {
      final bag = MoneyBag.of(const [Money(14200, 'USD'), Money(100, 'CDF')]);
      expect(ExpenseUsdReader.withoutRate.usdCentsOfBag(bag), isNull);
      expect(ExpenseUsdReader(_rate2800).usdCentsOfBag(bag), 14200);
    });

    test('l’euro ne se lit pas en dollars : aucune paire publiée', () {
      expect(
        ExpenseUsdReader(_rate2800).usdCentsOf(const Money(100, 'EUR')),
        isNull,
      );
    });
  });

  group('ExpenseTotals', () {
    test('sac par devise, jamais additionné ; lecture et moyenne', () {
      final totals = ExpenseTotals.of([
        _expense(14200, 'USD'),
        _expense(38500000, 'CDF'),
        _expense(1000, 'USD'),
      ], ExpenseUsdReader(_rate2800));

      expect(totals.count, 3);
      expect(totals.bag.amountIn('USD')!.amountInCents, 15200);
      expect(totals.bag.amountIn('CDF')!.amountInCents, 38500000);
      expect(totals.usdCents, 15200 + 13750);
      expect(totals.averageUsdCents, ((15200 + 13750) / 3).round());
    });

    test('sans taux : la paire reste, la lecture et la moyenne tombent', () {
      final totals = ExpenseTotals.of([
        _expense(14200, 'USD'),
        _expense(100, 'CDF'),
      ], ExpenseUsdReader.withoutRate);
      expect(totals.bag.length, 2);
      expect(totals.usdCents, isNull);
      expect(totals.averageUsdCents, isNull);
    });
  });

  group('expenseVariationPercent', () {
    ExpenseTotals usd(int cents) => ExpenseTotals.of([
      _expense(cents, 'USD'),
    ], ExpenseUsdReader.withoutRate);

    test('hausse et baisse en pourcents arrondis', () {
      expect(expenseVariationPercent(usd(15000), usd(10000)), 50);
      expect(expenseVariationPercent(usd(7000), usd(10000)), -30);
    });

    test('référence nulle : une hausse « infinie » n’informe pas', () {
      expect(expenseVariationPercent(usd(15000), ExpenseTotals.zero), isNull);
    });

    test('sans lecture, seule une même devise unique se compare', () {
      ExpenseTotals cdf(int cents) => ExpenseTotals.of([
        _expense(cents, 'CDF'),
      ], ExpenseUsdReader.withoutRate);
      expect(expenseVariationPercent(cdf(200), cdf(100)), 100);
      expect(expenseVariationPercent(cdf(200), usd(100)), isNull);
    });
  });
}
