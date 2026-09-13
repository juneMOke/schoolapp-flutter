import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';

/// Les trois filtres du registre, combinés en ET après la période.
class ExpenseQuery extends Equatable {
  /// Types retenus — **vide = tous**, jamais « aucun ».
  final Set<String> typeIds;

  /// `null` = toutes.
  final ExpenseStatus? status;
  final String text;

  const ExpenseQuery({this.typeIds = const {}, this.status, this.text = ''});

  static const none = ExpenseQuery();

  bool get isActive =>
      typeIds.isNotEmpty || status != null || text.trim().isNotEmpty;

  ExpenseQuery toggleType(String typeId) {
    final next = {...typeIds};
    if (!next.remove(typeId)) next.add(typeId);
    return ExpenseQuery(typeIds: next, status: status, text: text);
  }

  ExpenseQuery withStatus(ExpenseStatus? value) =>
      ExpenseQuery(typeIds: typeIds, status: value, text: text);

  ExpenseQuery withText(String value) =>
      ExpenseQuery(typeIds: typeIds, status: status, text: value);

  ExpenseQuery withoutTypes() => ExpenseQuery(status: status, text: text);

  @override
  List<Object?> get props => [typeIds, status, text];
}

/// Les lignes d'un même jour, dans l'ordre du registre.
class ExpenseDayGroup extends Equatable {
  final DateTime day;
  final List<Expense> expenses;

  const ExpenseDayGroup({required this.day, required this.expenses});

  @override
  List<Object?> get props => [day, expenses];
}

/// Requêtes du registre — pures, le jeu tient en mémoire (pas de debounce).
abstract final class ExpenseRegisterQuery {
  /// Les dépenses **visibles** de la période : un retrait quitte le
  /// registre, sur ce poste comme sur les autres.
  static List<Expense> inRange(
    Iterable<Expense> expenses,
    ExpenseDateRange range,
  ) {
    final rows = [
      for (final expense in expenses)
        if (!expense.isWithdrawn && range.containsKey(expense.dayKey)) expense,
    ]..sort(compare);
    return rows;
  }

  /// Applique types × statut × texte (A7 : casse et accents ignorés).
  static List<Expense> apply(
    List<Expense> rows,
    ExpenseQuery query,
    Map<String, ExpenseType> typesById,
  ) {
    if (!query.isActive) return rows;
    final text = query.text.trim();
    return [
      for (final expense in rows)
        if ((query.typeIds.isEmpty || query.typeIds.contains(expense.typeId)) &&
            (query.status == null || expense.status == query.status) &&
            (text.isEmpty ||
                SearchNormalizationHelper.contains(
                  _haystack(expense, typesById[expense.typeId]),
                  text,
                )))
          expense,
    ];
  }

  /// Nombre de dépenses de la période par type — **indépendant** des autres
  /// filtres : la puce dit ce qu'elle apporterait.
  static Map<String, int> countByType(Iterable<Expense> rows) {
    final counts = <String, int>{};
    for (final expense in rows) {
      counts.update(expense.typeId, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  /// Regroupe des lignes **déjà triées** par jour, sans les réordonner.
  static List<ExpenseDayGroup> groupByDay(List<Expense> sorted) {
    final groups = <ExpenseDayGroup>[];
    String? currentKey;
    List<Expense>? bucket;
    for (final expense in sorted) {
      if (expense.dayKey != currentKey) {
        currentKey = expense.dayKey;
        bucket = [];
        groups.add(ExpenseDayGroup(day: expense.expenseDate, expenses: bucket));
      }
      bucket!.add(expense);
    }
    return groups;
  }

  /// Ordre du registre : jour décroissant, puis la saisie la plus récente
  /// d'abord — une dépense pas encore numérotée est la plus récente, puis le
  /// numéro serveur, séquentiel par école, décroît.
  static int compare(Expense a, Expense b) {
    final byDay = b.dayKey.compareTo(a.dayKey);
    if (byDay != 0) return byDay;
    final byNumber = _numberRank(b.number).compareTo(_numberRank(a.number));
    if (byNumber != 0) return byNumber;
    final byClock = b.clientUpdatedAt.compareTo(a.clientUpdatedAt);
    return byClock != 0 ? byClock : a.id.compareTo(b.id);
  }

  /// `DEP-0412` → 412 ; sans numéro → le plus grand rang (en tête).
  static int _numberRank(String? number) {
    if (number == null) return 1 << 62;
    final digits = RegExp(r'(\d+)$').firstMatch(number)?.group(1);
    return digits == null ? 0 : int.tryParse(digits) ?? 0;
  }

  static String _haystack(Expense expense, ExpenseType? type) => [
    expense.title,
    expense.supplier ?? '',
    expense.number ?? '',
    type?.label ?? '',
    type?.shortLabel ?? '',
    expense.description ?? '',
  ].join(' ');
}
