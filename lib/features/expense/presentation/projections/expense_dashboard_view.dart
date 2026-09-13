import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_period_resolver.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_register_query.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_series_builder.dart';

/// Une barre de l'évolution : sa maille et ce qu'elle totalise.
class ExpenseSeriesPoint extends Equatable {
  final ExpenseSeriesBucket bucket;
  final ExpenseTotals totals;

  const ExpenseSeriesPoint({required this.bucket, required this.totals});

  @override
  List<Object?> get props => [bucket, totals];
}

/// Un poste : un type et ce qu'il pèse sur la période.
class ExpenseTypeShare extends Equatable {
  final String typeId;

  /// `null` pour un type que le socle ne nomme plus (jamais descendu).
  final ExpenseType? type;
  final ExpenseTotals totals;

  const ExpenseTypeShare({
    required this.typeId,
    required this.type,
    required this.totals,
  });

  @override
  List<Object?> get props => [typeId, type, totals];
}

/// Ce que le tableau de bord affiche — agrégats de la période, calculés sur
/// la même liste locale que le registre.
class ExpenseDashboardView extends Equatable {
  final ExpenseDateRange range;
  final ExpenseTotals total;
  final ExpenseTotals unpaid;

  /// Variation contre la période précédente (A6), `null` si elle n'informe
  /// pas (référence nulle, totaux non comparables).
  final int? variationPercent;

  /// La variation compare une période en cours à durée écoulée égale.
  final bool variationElapsedOnly;
  final List<ExpenseSeriesPoint> series;

  /// Postes de la période, du plus lourd au plus léger ; les types à zéro
  /// sont écartés (ils restent dans les puces du registre, pas ici).
  final List<ExpenseTypeShare> shares;

  /// La plus ancienne dépense non payée de la période, ou `null`.
  final Expense? oldestUnpaid;

  /// Les postes se classent par lecture en dollars ; sans lecture possible
  /// (A5), par nombre de dépenses — jamais par des montants de devises
  /// différentes mis côte à côte.
  final bool sharesRankedByCount;

  const ExpenseDashboardView({
    required this.range,
    required this.total,
    required this.unpaid,
    required this.variationPercent,
    required this.variationElapsedOnly,
    required this.series,
    required this.shares,
    required this.oldestUnpaid,
    required this.sharesRankedByCount,
  });

  factory ExpenseDashboardView.compute({
    required ExpenseRegisterSnapshot snapshot,
    required ExpensePeriod period,
    required DateTime today,
  }) {
    final resolver = ExpensePeriodResolver(
      today: today,
      anchor: snapshot.anchor,
    );
    final reader = snapshot.usdReader;
    final range = resolver.rangeOf(period);
    final rows = ExpenseRegisterQuery.inRange(snapshot.expenses, range);
    final unpaidRows = [
      for (final e in rows)
        if (e.status == ExpenseStatus.unpaid) e,
    ];

    final windows = resolver.comparisonOf(period);
    final current = ExpenseTotals.of(
      ExpenseRegisterQuery.inRange(snapshot.expenses, windows.current),
      reader,
    );
    final reference = ExpenseTotals.of(
      ExpenseRegisterQuery.inRange(snapshot.expenses, windows.reference),
      reader,
    );

    final buckets = ExpenseSeriesBuilder.build(
      period: period,
      range: range,
      today: today,
    );
    // La série « jour » déborde de la fenêtre (les 7 jours d'avant) : elle se
    // distribue sur tout le registre, pas sur les seules lignes de la journée.
    final lanes = ExpenseSeriesBuilder.distribute(
      buckets,
      snapshot.expenses.where((e) => !e.isWithdrawn),
    );

    final shares = _shares(rows, snapshot, reader);
    return ExpenseDashboardView(
      range: range,
      total: ExpenseTotals.of(rows, reader),
      unpaid: ExpenseTotals.of(unpaidRows, reader),
      variationPercent: expenseVariationPercent(current, reference),
      variationElapsedOnly: windows.elapsedOnly,
      series: [
        for (var i = 0; i < buckets.length; i++)
          ExpenseSeriesPoint(
            bucket: buckets[i],
            totals: ExpenseTotals.of(lanes[i], reader),
          ),
      ],
      shares: shares,
      // Le registre est trié du plus récent au plus ancien.
      oldestUnpaid: unpaidRows.isEmpty ? null : unpaidRows.last,
      sharesRankedByCount: shares.any((s) => s.totals.usdCents == null),
    );
  }

  static List<ExpenseTypeShare> _shares(
    List<Expense> rows,
    ExpenseRegisterSnapshot snapshot,
    ExpenseUsdReader reader,
  ) {
    final byType = <String, List<Expense>>{};
    for (final e in rows) {
      byType.putIfAbsent(e.typeId, () => []).add(e);
    }
    final types = snapshot.typesById;
    final shares = [
      for (final entry in byType.entries)
        ExpenseTypeShare(
          typeId: entry.key,
          type: types[entry.key],
          totals: ExpenseTotals.of(entry.value, reader),
        ),
    ];
    final byCount = shares.any((s) => s.totals.usdCents == null);
    shares.sort((a, b) {
      final primary = byCount
          ? b.totals.count.compareTo(a.totals.count)
          : b.totals.usdCents!.compareTo(a.totals.usdCents!);
      if (primary != 0) return primary;
      return (a.type?.sortOrder ?? 1 << 30).compareTo(
        b.type?.sortOrder ?? 1 << 30,
      );
    });
    return shares;
  }

  bool get isEmpty => total.isEmpty;

  @override
  List<Object?> get props => [
    range,
    total,
    unpaid,
    variationPercent,
    variationElapsedOnly,
    series,
    shares,
    oldestUnpaid,
    sharesRankedByCount,
  ];
}
