import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';

/// Tout ce que les deux écrans lisent, en une lecture locale.
///
/// Le registre tient en mémoire : filtres, compteurs, groupes, séries et
/// variation se recalculent sur ce seul objet, sans aller-retour — changer de
/// période ou de filtre ne rejoue jamais de chargement.
class ExpenseRegisterSnapshot extends Equatable {
  /// Types de l'école, masqués compris, dans l'ordre de l'école.
  final List<ExpenseType> types;

  /// Le registre entier, retraits compris (le domaine les écarte de la vue).
  final List<Expense> expenses;

  /// Le taux du jour `USD → CDF`, ou `null` s'il n'est pas publié (A5).
  final ExchangeRate? usdToCdf;

  /// Le jour de rentrée qui ouvre l'année scolaire (D2).
  final SchoolYearAnchor anchor;

  const ExpenseRegisterSnapshot({
    required this.types,
    required this.expenses,
    this.usdToCdf,
    this.anchor = SchoolYearAnchor.september,
  });

  static const ExpenseRegisterSnapshot empty = ExpenseRegisterSnapshot(
    types: [],
    expenses: [],
  );

  ExpenseUsdReader get usdReader => ExpenseUsdReader(usdToCdf);

  Map<String, ExpenseType> get typesById => {for (final t in types) t.id: t};

  /// Les types proposés à la saisie : les masqués nomment encore leurs
  /// dépenses, mais ne se choisissent plus.
  List<ExpenseType> get activeTypes => [
    for (final t in types)
      if (t.active) t,
  ];

  @override
  List<Object?> get props => [types, expenses, usdToCdf, anchor];
}
