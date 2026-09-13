import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';

ExpenseType _type(String code, String currency) => ExpenseType(
  id: 't-$code',
  code: code,
  label: code,
  shortLabel: code,
  icon: 'layers',
  colorHex: '#000000',
  softColorHex: '#FFFFFF',
  defaultCurrency: currency,
  sortOrder: 0,
  active: true,
);

final _paidCdf = Expense(
  id: 'e-1',
  number: 'DEP-0412',
  typeId: 't-ELECTRICITE',
  title: 'Facture SNEL',
  description: 'Compteur B',
  amountInCents: 38500050,
  currency: 'CDF',
  status: ExpenseStatus.paid,
  paidOn: DateTime(2026, 8, 3),
  expenseDate: DateTime(2026, 8, 3),
  supplier: 'SNEL',
  fundingSource: ExpenseFundingSource.bank,
  clientUpdatedAt: DateTime.utc(2026, 8, 3),
);

void main() {
  final today = DateTime(2026, 9, 12, 15, 30);

  test('création : le premier type offert (ordre du référentiel, aucun code '
      'en dur), sa devise, payée, aujourd’hui', () {
    final seed = ExpenseFormSeed.blank(
      types: [_type('ELECTRICITE', 'cdf'), _type('FOURNITURES', 'USD')],
      today: today,
    );
    expect(seed.mode, ExpenseFormMode.create);
    expect(seed.id, isNull);
    expect(seed.typeId, 't-ELECTRICITE');
    expect(seed.currency, 'CDF');
    expect(seed.status, ExpenseStatus.paid);
    expect(seed.expenseDate, DateTime(2026, 9, 12));
  });

  test('création sans type offert : aucun type, le dollar par défaut', () {
    final seed = ExpenseFormSeed.blank(types: const [], today: today);
    expect(seed.typeId, isEmpty);
    expect(seed.currency, 'USD');
  });

  test('duplication : id vidé, date du jour, non payée — le reste recopié', () {
    final seed = ExpenseFormSeed.duplicate(_paidCdf, today: today);
    expect(seed.id, isNull);
    expect(seed.expenseDate, DateTime(2026, 9, 12));
    expect(seed.status, ExpenseStatus.unpaid);
    expect(seed.title, 'Facture SNEL');
    expect(seed.currency, 'CDF');
    expect(seed.fundingSource, ExpenseFundingSource.bank);
    expect(seed.amountText, '385000,50');
  });

  test('modification : l’identifiant et le numéro sont gardés', () {
    final seed = ExpenseFormSeed.edit(_paidCdf);
    expect(seed.isEdit, isTrue);
    expect(seed.id, 'e-1');
    expect(seed.number, 'DEP-0412');
    expect(seed.expenseDate, DateTime(2026, 8, 3));
  });
}
