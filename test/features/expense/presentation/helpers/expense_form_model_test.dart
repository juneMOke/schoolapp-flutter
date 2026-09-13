import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_model.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_form_seed.dart';

ExpenseType _type(String id, String currency) => ExpenseType(
  id: id,
  code: id.toUpperCase(),
  label: id,
  shortLabel: id,
  icon: 'layers',
  colorHex: '#000000',
  softColorHex: '#FFFFFF',
  defaultCurrency: currency,
  sortOrder: 0,
  active: true,
);

final _types = [_type('t-elec', 'CDF'), _type('t-four', 'USD')];
final _today = DateTime(2026, 9, 12);

ExpenseFormModel _create() {
  final form = ExpenseFormModel(
    ExpenseFormSeed.blank(types: _types, today: _today),
    types: _types,
  );
  addTearDown(form.dispose);
  return form;
}

void main() {
  group('la devise suit le type…', () {
    test('en création, montant vide : le type propose la sienne', () {
      final form = _create();
      expect(form.currency, 'CDF');
      form.selectType('t-four');
      expect(form.typeId, 't-four');
      expect(form.currency, 'USD');
    });

    test('…sauf après un choix explicite de l’agent', () {
      final form = _create()..chooseCurrency('CDF');
      form.selectType('t-four');
      expect(form.currency, 'CDF');
    });

    test('…sauf quand un montant est déjà saisi : il a été pensé dans une '
        'devise', () {
      final form = _create()..amount.text = '385000';
      form.selectType('t-four');
      expect(form.currency, 'CDF');
    });

    test('…et jamais sur une dépense existante : elle a la sienne', () {
      final form = ExpenseFormModel(
        ExpenseFormSeed.edit(
          Expense(
            id: 'e-1',
            number: 'DEP-0412',
            typeId: 't-elec',
            title: 'Facture SNEL',
            amountInCents: 38500000,
            currency: 'CDF',
            status: ExpenseStatus.paid,
            expenseDate: DateTime(2026, 9, 3),
            clientUpdatedAt: DateTime.utc(2026, 9, 3),
          ),
        ),
        types: _types,
      );
      addTearDown(form.dispose);
      form.amount.text = '';
      form.selectType('t-four');
      expect(form.typeId, 't-four');
      expect(form.currency, 'CDF');
    });
  });

  test('brouillon : rien tant qu’il manque l’intitulé ou le montant ; des '
      'centimes ensuite', () {
    final form = _create();
    expect(form.draft(), isNull);
    form.title.text = '  Ramettes A4  ';
    expect(form.draft(), isNull);
    form.amount.text = '142,50';
    final draft = form.draft(recordedByName: 'Moke Junior')!;
    expect(draft.title, 'Ramettes A4');
    expect(draft.amountInCents, 14250);
    expect(draft.currency, 'CDF');
    expect(draft.recordedByName, 'Moke Junior');
  });
}
