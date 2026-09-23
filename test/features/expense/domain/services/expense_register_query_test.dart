import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_register_query.dart';

Expense _expense(
  String id, {
  required String day,
  String typeId = 't-elec',
  String title = 'Facture',
  String? number,
  String? supplier,
  ExpenseStatus status = ExpenseStatus.paid,
  DateTime? deletedAt,
}) => Expense(
  id: id,
  number: number,
  typeId: typeId,
  title: title,
  amountInCents: 100,
  currency: 'USD',
  status: status,
  expenseDate: DateTime.parse(day),
  supplier: supplier,
  clientUpdatedAt: DateTime.utc(2026, 9, 1),
  deletedAt: deletedAt,
);

const _elec = ExpenseType(
  id: 't-elec',
  code: 'ELECTRICITE',
  label: 'Électricité & eau',
  shortLabel: 'Électricité',
  icon: 'power',
  colorHex: '#D9A24E',
  softColorHex: '#FBF3E3',
  defaultCurrency: 'CDF',
  sortOrder: 0,
  active: true,
);

void main() {
  final september = ExpenseDateRange(
    from: DateTime(2026, 9, 1),
    to: DateTime(2026, 9, 30),
  );

  group('inRange', () {
    test('bornes incluses, retraits écartés, tri du registre', () {
      final rows = ExpenseRegisterQuery.inRange([
        _expense('a', day: '2026-08-31'),
        _expense('b', day: '2026-09-01', number: 'DEP-0009'),
        _expense('c', day: '2026-09-30', number: 'DEP-0010'),
        _expense('d', day: '2026-09-30', number: 'DEP-0011'),
        _expense('e', day: '2026-09-30'),
        _expense('f', day: '2026-09-15', deletedAt: DateTime.utc(2026, 9, 16)),
        _expense('g', day: '2026-10-01'),
      ], september);
      // Le 30 d'abord ; dans le jour, la saisie pas encore numérotée puis
      // les numéros décroissants.
      expect(rows.map((e) => e.id), ['e', 'd', 'c', 'b']);
    });

    test('DEP-10000 passe devant DEP-9999 (tri numérique)', () {
      final rows = ExpenseRegisterQuery.inRange([
        _expense('old', day: '2026-09-02', number: 'DEP-9999'),
        _expense('new', day: '2026-09-02', number: 'DEP-10000'),
      ], september);
      expect(rows.first.id, 'new');
    });
  });

  group('apply', () {
    final rows = [
      _expense(
        'snel',
        day: '2026-09-03',
        title: 'Facture SNEL',
        supplier: 'SNEL',
      ),
      _expense(
        'papier',
        day: '2026-09-03',
        typeId: 't-four',
        title: 'Ramettes de papier',
        status: ExpenseStatus.pending,
        number: 'DEP-0413',
      ),
    ];
    final types = {'t-elec': _elec};

    test('aucun filtre : la liste intacte', () {
      expect(ExpenseRegisterQuery.apply(rows, ExpenseQuery.none, types), rows);
    });

    test('recherche insensible aux accents, sur le libellé du type (A7)', () {
      final hits = ExpenseRegisterQuery.apply(
        rows,
        const ExpenseQuery(text: 'electricite'),
        types,
      );
      expect(hits.map((e) => e.id), ['snel']);
    });

    test('recherche sur le numéro et le fournisseur', () {
      expect(
        ExpenseRegisterQuery.apply(
          rows,
          const ExpenseQuery(text: '0413'),
          types,
        ).single.id,
        'papier',
      );
      expect(
        ExpenseRegisterQuery.apply(
          rows,
          const ExpenseQuery(text: 'snel'),
          types,
        ).single.id,
        'snel',
      );
    });

    test('types × statut en ET', () {
      final hits = ExpenseRegisterQuery.apply(
        rows,
        const ExpenseQuery(
          typeIds: {'t-elec', 't-four'},
          status: ExpenseStatus.pending,
        ),
        types,
      );
      expect(hits.map((e) => e.id), ['papier']);
    });
  });

  test('countByType ignore les autres filtres', () {
    final counts = ExpenseRegisterQuery.countByType([
      _expense('a', day: '2026-09-01'),
      _expense('b', day: '2026-09-02'),
      _expense('c', day: '2026-09-02', typeId: 't-four'),
    ]);
    expect(counts, {'t-elec': 2, 't-four': 1});
  });

  test('groupByDay garde l’ordre et coupe à chaque jour', () {
    final groups = ExpenseRegisterQuery.groupByDay([
      _expense('a', day: '2026-09-03'),
      _expense('b', day: '2026-09-03'),
      _expense('c', day: '2026-09-01'),
    ]);
    expect(groups.map((g) => g.expenses.length), [2, 1]);
    expect(groups.first.day, DateTime(2026, 9, 3));
  });

  test('ExpenseQuery.toggleType ajoute puis retire', () {
    final once = ExpenseQuery.none.toggleType('t-elec');
    expect(once.typeIds, {'t-elec'});
    expect(once.toggleType('t-elec').isActive, isFalse);
  });
}
