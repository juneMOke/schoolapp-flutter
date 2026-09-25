import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_period_resolver.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_register_query.dart';

/// Ce que le registre affiche, calculé en une passe (spec §11) : période, puis
/// filtres en ET, puis compteurs et groupes de jour.
///
/// Recalculé à chaque changement de filtre ou de période **sans chargement**
/// — le jeu tient en mémoire.
class ExpenseRegisterView extends Equatable {
  final ExpenseDateRange range;

  /// Dépenses de la période par type, indépendamment des autres filtres.
  final Map<String, int> typeCounts;

  /// Les lignes retenues, dans l'ordre du registre.
  final List<Expense> rows;

  /// **Les engagements fermes de la sélection**, et eux seuls : une demande
  /// en attente, refusée ou retirée n'est pas de l'argent sorti (spec §16
  /// règle 3). Le registre ne totalise rien d'autre.
  final ExpenseTotals total;

  /// Les groupes de jour des [limit] premières lignes seulement : un palier
  /// « 40 de plus » ne recalcule jamais les groupes déjà rendus.
  final List<ExpenseDayGroup> groups;

  /// Effectif et total de chaque journée (`YYYY-MM-DD`) sur TOUTES les lignes
  /// retenues : le palier coupe une journée, jamais ce que son en-tête annonce.
  final Map<String, ExpenseTotals> dayTotals;

  /// Lignes qui restent au-delà du palier.
  final int remaining;

  const ExpenseRegisterView({
    required this.range,
    required this.typeCounts,
    required this.rows,
    required this.total,
    required this.groups,
    required this.dayTotals,
    required this.remaining,
  });

  factory ExpenseRegisterView.compute({
    required ExpenseRegisterSnapshot snapshot,
    required ExpensePeriod period,
    required ExpenseQuery query,
    required int limit,
    required DateTime today,
  }) {
    final resolver = ExpensePeriodResolver(
      today: today,
      anchor: snapshot.anchor,
    );
    final range = resolver.rangeOf(period);
    final inRange = ExpenseRegisterQuery.inRange(snapshot.expenses, range);
    final rows = ExpenseRegisterQuery.apply(inRange, query, snapshot.typesById);
    final reader = snapshot.usdReader;
    final shown = rows.length <= limit ? rows : rows.sublist(0, limit);
    // Les en-têtes de jour annoncent ce qui est « engagé » : seules les
    // demandes fermes y entrent, sur TOUTES les lignes retenues — le palier
    // coupe une journée, jamais ce que son en-tête annonce.
    final byDay = <String, List<Expense>>{};
    for (final expense in rows) {
      if (expense.isFirm) (byDay[expense.dayKey] ??= []).add(expense);
    }
    return ExpenseRegisterView(
      range: range,
      typeCounts: ExpenseRegisterQuery.countByType(inRange),
      rows: rows,
      total: ExpenseTotals.of(rows.where((e) => e.isFirm), reader),
      groups: ExpenseRegisterQuery.groupByDay(shown),
      dayTotals: {
        for (final day in byDay.entries)
          day.key: ExpenseTotals.of(day.value, reader),
      },
      remaining: rows.length - shown.length,
    );
  }

  bool get isEmpty => rows.isEmpty;

  @override
  List<Object?> get props => [
    range,
    typeCounts,
    rows,
    total,
    groups,
    dayTotals,
    remaining,
  ];
}
