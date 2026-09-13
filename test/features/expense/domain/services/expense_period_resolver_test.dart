import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_period_resolver.dart';

void main() {
  // Samedi 12 septembre 2026.
  final saturday = DateTime(2026, 9, 12, 17, 45);
  final resolver = ExpensePeriodResolver(today: saturday);

  ExpenseDateRange range(ExpenseGranularity g, [int offset = 0]) =>
      resolver.rangeOf(ExpensePeriod(granularity: g, offset: offset));

  group('rangeOf', () {
    test('jour : aujourd’hui, sans heure, puis la veille', () {
      expect(range(ExpenseGranularity.day).fromKey, '2026-09-12');
      expect(range(ExpenseGranularity.day).toKey, '2026-09-12');
      expect(range(ExpenseGranularity.day, -1).fromKey, '2026-09-11');
    });

    test('semaine ISO : du lundi au dimanche, le dimanche la ferme', () {
      final week = range(ExpenseGranularity.week);
      expect(week.fromKey, '2026-09-07');
      expect(week.toKey, '2026-09-13');
      final sunday = ExpensePeriodResolver(today: DateTime(2026, 9, 13));
      expect(
        sunday
            .rangeOf(const ExpensePeriod(granularity: ExpenseGranularity.week))
            .fromKey,
        '2026-09-07',
      );
      expect(range(ExpenseGranularity.week, -1).fromKey, '2026-08-31');
      expect(range(ExpenseGranularity.week, -1).toKey, '2026-09-06');
    });

    test('mois : du 1ᵉʳ au dernier jour, février bissextile compris', () {
      expect(range(ExpenseGranularity.month).fromKey, '2026-09-01');
      expect(range(ExpenseGranularity.month).toKey, '2026-09-30');
      final february = ExpensePeriodResolver(today: DateTime(2028, 3, 10));
      final feb = february.rangeOf(
        const ExpensePeriod(granularity: ExpenseGranularity.month, offset: -1),
      );
      expect(feb.toKey, '2028-02-29');
      // Traverser le 1ᵉʳ janvier vers le passé.
      expect(range(ExpenseGranularity.month, -9).fromKey, '2025-12-01');
    });

    test('année scolaire : de la rentrée à la veille de la suivante', () {
      final year = range(ExpenseGranularity.schoolYear);
      expect(year.fromKey, '2026-09-01');
      expect(year.toKey, '2027-08-31');
      expect(range(ExpenseGranularity.schoolYear, -1).fromKey, '2025-09-01');
      expect(range(ExpenseGranularity.schoolYear, -1).toKey, '2026-08-31');
    });

    test(
      'année scolaire : avant la rentrée, on est encore dans la précédente',
      () {
        final july = ExpensePeriodResolver(today: DateTime(2026, 7, 20));
        final year = july.rangeOf(
          const ExpensePeriod(granularity: ExpenseGranularity.schoolYear),
        );
        expect(year.fromKey, '2025-09-01');
        expect(year.toKey, '2026-08-31');
      },
    );

    test('année scolaire : ancrée sur le jour de rentrée du référentiel', () {
      final anchored = ExpensePeriodResolver(
        today: DateTime(2026, 9, 3),
        anchor: SchoolYearAnchor.fromStartDate(DateTime(2025, 9, 7)),
      );
      final year = anchored.rangeOf(
        const ExpensePeriod(granularity: ExpenseGranularity.schoolYear),
      );
      // Le 3 septembre précède la rentrée du 7 : toujours 2025-2026.
      expect(year.fromKey, '2025-09-07');
      expect(year.toKey, '2026-09-06');
    });

    test('les années se touchent : aucun jour entre deux', () {
      final current = range(ExpenseGranularity.schoolYear);
      final previous = range(ExpenseGranularity.schoolYear, -1);
      expect(previous.to.add(const Duration(days: 1)), current.from);
    });
  });

  group('comparisonOf (A6)', () {
    test('mois en cours : à durée écoulée égale', () {
      final windows = resolver.comparisonOf(ExpensePeriod.initial);
      expect(windows.elapsedOnly, isTrue);
      expect(windows.current.fromKey, '2026-09-01');
      expect(windows.current.toKey, '2026-09-12');
      expect(windows.reference.fromKey, '2026-08-01');
      expect(windows.reference.toKey, '2026-08-12');
    });

    test('mois passé : entier contre entier', () {
      final windows = resolver.comparisonOf(
        const ExpensePeriod(granularity: ExpenseGranularity.month, offset: -1),
      );
      expect(windows.elapsedOnly, isFalse);
      expect(windows.current.toKey, '2026-08-31');
      expect(windows.reference.fromKey, '2026-07-01');
      expect(windows.reference.toKey, '2026-07-31');
    });

    test('la référence tronquée ne déborde jamais de son mois', () {
      final march31 = ExpensePeriodResolver(today: DateTime(2027, 3, 31));
      final windows = march31.comparisonOf(ExpensePeriod.initial);
      expect(windows.reference.fromKey, '2027-02-01');
      expect(windows.reference.toKey, '2027-02-28');
    });

    test('jour : aujourd’hui contre hier, entier', () {
      final windows = resolver.comparisonOf(
        const ExpensePeriod(granularity: ExpenseGranularity.day),
      );
      expect(windows.elapsedOnly, isFalse);
      expect(windows.reference.fromKey, '2026-09-11');
    });
  });

  group('ExpensePeriod', () {
    test('changer de maille remet le pas à zéro', () {
      const period = ExpensePeriod(offset: -3);
      expect(period.withGranularity(ExpenseGranularity.week).offset, 0);
    });

    test('le pas suivant s’arrête à la période en cours', () {
      expect(ExpensePeriod.initial.next(), ExpensePeriod.initial);
      expect(const ExpensePeriod(offset: -1).next(), ExpensePeriod.initial);
    });
  });
}
