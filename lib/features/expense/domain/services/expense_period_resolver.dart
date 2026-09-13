import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';

/// Ce que la variation compare : la période et sa référence, chacune bornée.
class ExpenseComparisonWindows {
  final ExpenseDateRange current;
  final ExpenseDateRange reference;

  /// `true` quand la période en cours est incomplète et que la référence a
  /// été ramenée à la même durée écoulée (A6).
  final bool elapsedOnly;

  const ExpenseComparisonWindows({
    required this.current,
    required this.reference,
    required this.elapsedOnly,
  });
}

/// Résout une [ExpensePeriod] en bornes de jours, pour un « aujourd'hui » et
/// une rentrée donnés.
///
/// Toutes les bornes sont **incluses** et contiguës d'une période à la
/// suivante : aucun jour ne tombe entre deux semaines, deux mois ou deux
/// années scolaires — une dépense de juillet appartient toujours à une année.
class ExpensePeriodResolver {
  final DateTime today;
  final SchoolYearAnchor anchor;

  ExpensePeriodResolver({
    required DateTime today,
    this.anchor = SchoolYearAnchor.september,
  }) : today = ExpenseDay.of(today);

  ExpenseDateRange rangeOf(ExpensePeriod period) {
    final offset = period.offset;
    switch (period.granularity) {
      case ExpenseGranularity.day:
        final day = ExpenseDay.addDays(today, offset);
        return ExpenseDateRange(from: day, to: day);
      case ExpenseGranularity.week:
        final from = ExpenseDay.addDays(
          ExpenseDay.startOfIsoWeek(today),
          offset * DateTime.daysPerWeek,
        );
        return ExpenseDateRange(from: from, to: ExpenseDay.addDays(from, 6));
      case ExpenseGranularity.month:
        return ExpenseDateRange(
          from: DateTime(today.year, today.month + offset, 1),
          to: DateTime(today.year, today.month + offset + 1, 0),
        );
      case ExpenseGranularity.schoolYear:
        final startYear = currentSchoolYearStartYear + offset;
        return ExpenseDateRange(
          from: _anchorIn(startYear),
          to: ExpenseDay.addDays(_anchorIn(startYear + 1), -1),
        );
    }
  }

  /// L'année civile de la rentrée qui ouvre l'année scolaire en cours.
  int get currentSchoolYearStartYear =>
      today.isBefore(_anchorIn(today.year)) ? today.year - 1 : today.year;

  /// Les deux fenêtres de la variation (A6) : une période **en cours** se
  /// compare à la précédente sur la même durée écoulée — « du 1ᵉʳ au 12
  /// septembre vs du 1ᵉʳ au 12 août » ; une période passée, entière.
  ExpenseComparisonWindows comparisonOf(ExpensePeriod period) {
    final range = rangeOf(period);
    final reference = rangeOf(period.previous());
    final partial = period.isCurrent && range.to.isAfter(today);
    if (!partial) {
      return ExpenseComparisonWindows(
        current: range,
        reference: reference,
        elapsedOnly: false,
      );
    }
    final elapsed = ExpenseDay.spanInclusive(range.from, today);
    final referenceEnd = ExpenseDay.addDays(reference.from, elapsed - 1);
    return ExpenseComparisonWindows(
      current: ExpenseDateRange(from: range.from, to: today),
      reference: ExpenseDateRange(
        from: reference.from,
        to: referenceEnd.isAfter(reference.to) ? reference.to : referenceEnd,
      ),
      elapsedOnly: true,
    );
  }

  DateTime _anchorIn(int year) => DateTime(year, anchor.month, anchor.day);
}
