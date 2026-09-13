import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_period_resolver.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_series_builder.dart';

void main() {
  final today = DateTime(2026, 9, 12);
  final resolver = ExpensePeriodResolver(today: today);

  List<ExpenseSeriesBucket> build(ExpensePeriod period, [DateTime? now]) {
    final r = now == null ? resolver : ExpensePeriodResolver(today: now);
    return ExpenseSeriesBuilder.build(
      period: period,
      range: r.rangeOf(period),
      today: now ?? today,
    );
  }

  test('jour : les 7 jours jusqu’à la journée consultée', () {
    final buckets = build(
      const ExpensePeriod(granularity: ExpenseGranularity.day, offset: -2),
    );
    expect(buckets, hasLength(7));
    expect(buckets.first.range.fromKey, '2026-09-04');
    expect(buckets.last.range.fromKey, '2026-09-10');
    expect(buckets.last.highlighted, isTrue);
    expect(buckets.any((b) => b.future), isFalse);
  });

  test(
    'mois en cours : 30 barres, aujourd’hui en avant, la suite en creux',
    () {
      final buckets = build(ExpensePeriod.initial);
      expect(buckets, hasLength(30));
      expect(buckets[11].highlighted, isTrue);
      expect(buckets[11].future, isFalse);
      expect(buckets[12].future, isTrue);
    },
  );

  test('année scolaire : 12 mois de septembre à août (D2)', () {
    final buckets = build(
      const ExpensePeriod(granularity: ExpenseGranularity.schoolYear),
    );
    expect(buckets, hasLength(12));
    expect(buckets.first.unit, ExpenseSeriesUnit.month);
    expect(buckets.first.range.fromKey, '2026-09-01');
    expect(buckets.first.range.toKey, '2026-09-30');
    expect(buckets.last.range.fromKey, '2027-08-01');
    expect(buckets.first.highlighted, isTrue);
    expect(buckets[1].future, isTrue);
  });

  test('rentrée au 7 : la première barre commence au 7', () {
    final anchored = ExpensePeriodResolver(
      today: DateTime(2026, 10, 2),
      anchor: const SchoolYearAnchor(month: 9, day: 7),
    );
    const period = ExpensePeriod(granularity: ExpenseGranularity.schoolYear);
    final buckets = ExpenseSeriesBuilder.build(
      period: period,
      range: anchored.rangeOf(period),
      today: DateTime(2026, 10, 2),
    );
    expect(buckets.first.range.fromKey, '2026-09-07');
    // Toujours 12 barres : la queue de septembre suivant (1er → 6) rejoint
    // août au lieu d'ouvrir une 13ᵉ barre-moignon.
    expect(buckets, hasLength(12));
    expect(buckets.last.range.fromKey, '2027-08-01');
    expect(buckets.last.range.toKey, '2027-09-06');
  });

  test('distribute range chaque ligne dans sa barre', () {
    final buckets = build(
      const ExpensePeriod(granularity: ExpenseGranularity.week),
    );
    Expense at(String day) => Expense(
      id: day,
      typeId: 't',
      title: 'x',
      amountInCents: 1,
      currency: 'USD',
      status: ExpenseStatus.paid,
      expenseDate: DateTime.parse(day),
      clientUpdatedAt: DateTime.utc(2026),
    );
    final lanes = ExpenseSeriesBuilder.distribute(buckets, [
      at('2026-09-07'),
      at('2026-09-07'),
      at('2026-09-13'),
      at('2026-09-20'),
    ]);
    expect(lanes.map((l) => l.length), [2, 0, 0, 0, 0, 0, 1]);
  });
}
