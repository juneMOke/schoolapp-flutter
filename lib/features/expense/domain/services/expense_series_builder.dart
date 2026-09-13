import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';

/// La maille d'une barre du graphique d'évolution.
enum ExpenseSeriesUnit { day, month }

/// Une barre : un intervalle de jours et deux drapeaux de rendu.
class ExpenseSeriesBucket extends Equatable {
  final ExpenseDateRange range;
  final ExpenseSeriesUnit unit;

  /// Postérieure à aujourd'hui : rendue en creux, jamais comptée.
  final bool future;

  /// La barre mise en avant (aujourd'hui, ou la journée consultée).
  final bool highlighted;

  const ExpenseSeriesBucket({
    required this.range,
    required this.unit,
    required this.future,
    required this.highlighted,
  });

  DateTime get start => range.from;

  @override
  List<Object?> get props => [range, unit, future, highlighted];
}

/// Découpe une période en barres (spec §11, règle 6) : la maille suit la
/// granularité.
///
/// - jour → les 7 jours jusqu'à la journée consultée (une barre seule
///   n'apprend rien) ;
/// - semaine → ses 7 jours ; mois → ses 28 à 31 jours ;
/// - année scolaire → ses 12 mois, de la rentrée à août (D2).
abstract final class ExpenseSeriesBuilder {
  static List<ExpenseSeriesBucket> build({
    required ExpensePeriod period,
    required ExpenseDateRange range,
    required DateTime today,
  }) {
    final day = ExpenseDay.of(today);
    final ranges = switch (period.granularity) {
      ExpenseGranularity.day => _days(ExpenseDay.addDays(range.to, -6), 7),
      ExpenseGranularity.week ||
      ExpenseGranularity.month => _days(range.from, range.dayCount),
      ExpenseGranularity.schoolYear => _months(range),
    };
    final unit = period.granularity == ExpenseGranularity.schoolYear
        ? ExpenseSeriesUnit.month
        : ExpenseSeriesUnit.day;
    // Aujourd'hui s'il est dans la fenêtre, sinon la journée consultée ou la
    // dernière barre : la mise en avant désigne toujours une barre qui existe.
    var highlight = ranges.indexWhere((r) => r.contains(day));
    if (highlight < 0) highlight = ranges.length - 1;
    return [
      for (var i = 0; i < ranges.length; i++)
        ExpenseSeriesBucket(
          range: ranges[i],
          unit: unit,
          future: ranges[i].from.isAfter(day),
          highlighted: i == highlight,
        ),
    ];
  }

  /// Répartit des lignes dans les barres ; une ligne hors de toute barre est
  /// ignorée.
  static List<List<Expense>> distribute(
    List<ExpenseSeriesBucket> buckets,
    Iterable<Expense> rows,
  ) {
    final out = [for (final _ in buckets) <Expense>[]];
    for (final expense in rows) {
      final key = expense.dayKey;
      for (var i = 0; i < buckets.length; i++) {
        if (buckets[i].range.containsKey(key)) {
          out[i].add(expense);
          break;
        }
      }
    }
    return out;
  }

  static List<ExpenseDateRange> _days(DateTime from, int count) => [
    for (var i = 0; i < count; i++)
      ExpenseDateRange(
        from: ExpenseDay.addDays(from, i),
        to: ExpenseDay.addDays(from, i),
      ),
  ];

  static const _monthsPerYear = 12;

  /// Les mois civils qui recouvrent la fenêtre, chacun ramené à ses bornes
  /// (une rentrée au 7 septembre ouvre la première barre au 7).
  ///
  /// Toujours **12** barres pour une année : une rentrée hors du 1ᵉʳ fait
  /// déborder l'année sur un 13ᵉ mois civil (du 1ᵉʳ à la veille de la
  /// rentrée suivante) — cette queue rejoint la dernière barre plutôt que
  /// d'ouvrir une barre-moignon au bout du graphique.
  static List<ExpenseDateRange> _months(ExpenseDateRange range) {
    final out = <ExpenseDateRange>[];
    var cursor = DateTime(range.from.year, range.from.month, 1);
    while (!cursor.isAfter(range.to)) {
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
      out.add(
        ExpenseDateRange(
          from: cursor.isBefore(range.from) ? range.from : cursor,
          to: monthEnd.isAfter(range.to) ? range.to : monthEnd,
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    if (out.length <= _monthsPerYear) return out;
    final tail = ExpenseDateRange(
      from: out[_monthsPerYear - 1].from,
      to: out.last.to,
    );
    return [...out.take(_monthsPerYear - 1), tail];
  }
}
