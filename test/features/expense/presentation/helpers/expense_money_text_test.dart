import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';

final _rate = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2800 * ExchangeRate.scale,
  effectiveFrom: DateTime.utc(2026, 9, 1),
);

Expense _expense(String id, int cents, String currency) => Expense(
  id: id,
  typeId: 't',
  title: id,
  amountInCents: cents,
  currency: currency,
  status: ExpenseStatus.paid,
  expenseDate: DateTime(2026, 9, 3),
  clientUpdatedAt: DateTime.utc(2026, 9, 3),
);

void main() {
  final snel = _expense('snel', 38500000, 'CDF');
  final ramettes = _expense('ramettes', 14200, 'USD');

  test('une lecture qui convertit du franc est doublée de sa paire (F9)', () {
    final reading = ExpenseMoneyText.reading(
      ExpenseTotals.of([snel, ramettes], ExpenseUsdReader(_rate)),
    );
    // 385 000 FC ÷ 2 800 = 137,50 $ ; + 142,00 $.
    expect(reading.primary, contains('279,50'));
    expect(reading.pair, allOf(contains('385'), contains('142,00')));
  });

  test('des dollars seuls : la lecture suffit, pas de paire', () {
    final reading = ExpenseMoneyText.reading(
      ExpenseTotals.of([ramettes], ExpenseUsdReader(_rate)),
    );
    expect(reading.primary, contains('142,00'));
    expect(reading.pair, isNull);
  });

  test('sans taux : la paire seule, jamais un 1 pour 1', () {
    final reading = ExpenseMoneyText.reading(
      ExpenseTotals.of([snel, ramettes], ExpenseUsdReader.withoutRate),
    );
    expect(reading.primary, allOf(contains('385'), contains('142,00')));
    expect(reading.pair, isNull);
  });
}
