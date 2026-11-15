import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';

void main() {
  final thursday = DateTime(2026, 10, 22);

  test('la semaine va du lundi au samedi, semaine ISO', () {
    final range = CashClosingRules.rangeOf(ClosingScope.week, thursday);
    expect(range.from, DateTime(2026, 10, 19));
    expect(range.to, DateTime(2026, 10, 24));
  });

  test('un dimanche appartient à la semaine qu il ferme', () {
    final range = CashClosingRules.rangeOf(
      ClosingScope.week,
      DateTime(2026, 10, 25),
    );
    expect(range.from, DateTime(2026, 10, 19));
  });

  test('le mois va du 1er au dernier jour, février compris', () {
    final range = CashClosingRules.rangeOf(
      ClosingScope.month,
      DateTime(2027, 2, 12),
    );
    expect(range.from, DateTime(2027, 2));
    expect(range.to, DateTime(2027, 2, 28));
  });

  test('› s arrête à la période en cours', () {
    expect(
      CashClosingRules.stepPeriod(
        ClosingScope.week,
        thursday,
        direction: 1,
        min: DateTime(2026, 10, 1),
        today: thursday,
      ),
      isNull,
    );
  });

  test('‹ mène à la semaine précédente, puis s arrête avant l historique', () {
    final min = DateTime(2026, 10, 14); // mercredi de la semaine précédente
    final previous = CashClosingRules.stepPeriod(
      ClosingScope.week,
      thursday,
      direction: -1,
      min: min,
      today: thursday,
    );
    expect(previous, DateTime(2026, 10, 12));
    expect(
      CashClosingRules.stepPeriod(
        ClosingScope.week,
        previous!,
        direction: -1,
        min: min,
        today: thursday,
      ),
      isNull,
    );
  });

  test('‹ d un mois : le 1er du mois précédent', () {
    expect(
      CashClosingRules.stepPeriod(
        ClosingScope.month,
        DateTime(2026, 11, 15),
        direction: -1,
        min: DateTime(2026, 9, 2),
        today: DateTime(2026, 11, 15),
      ),
      DateTime(2026, 10),
    );
  });
}
