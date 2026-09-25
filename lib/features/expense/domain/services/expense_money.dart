import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';

/// La **lecture** en dollars d'un montant (doctrine bi-devise §12) — jamais
/// une conversion comptable : le montant enregistré n'est ni réécrit ni
/// stocké converti.
///
/// ## Sans taux, pas de total converti (A5)
///
/// Un montant en francs ne se lit en dollars qu'au taux **publié** par
/// l'école. Sans lui, la lecture rend `null` — jamais un 1 pour 1, jamais un
/// total partiel qui omettrait les francs. L'écran montre alors la paire
/// brute seule. Un montant déjà en dollars se lit tel quel, taux ou pas.
class ExpenseUsdReader extends Equatable {
  /// Le taux du jour `USD → CDF` (pivot dollar, franc reçu), ou `null`.
  final ExchangeRate? usdToCdf;

  const ExpenseUsdReader(this.usdToCdf);

  static const ExpenseUsdReader withoutRate = ExpenseUsdReader(null);

  bool get hasRate => usdToCdf != null && usdToCdf!.rateMicros > 0;

  /// Centimes de dollar lus pour [amount], ou `null` s'il ne se lit pas.
  ///
  /// Arrondi **au plus proche** : c'est une lecture, pas une imputation — la
  /// troncature de `ExchangeRates.settledCentsFrom` perdrait un centime à
  /// chaque ligne, toujours dans le même sens.
  int? usdCentsOf(Money amount) {
    final currency = CurrencyCode.normalize(amount.currency);
    if (currency == CurrencyCode.usd) return amount.amountInCents;
    final rate = usdToCdf;
    if (currency != CurrencyCode.cdf || rate == null || rate.rateMicros <= 0) {
      return null;
    }
    final micros = BigInt.from(rate.rateMicros);
    final scaled =
        BigInt.from(amount.amountInCents) * BigInt.from(ExchangeRate.scale);
    return ((scaled + micros ~/ BigInt.two) ~/ micros).toInt();
  }

  /// Lecture d'un sac entier : `null` dès qu'une devise ne se lit pas — un
  /// total qui omettrait les francs mentirait sans le dire.
  int? usdCentsOfBag(MoneyBag bag) {
    var total = 0;
    for (final entry in bag.entries) {
      final cents = usdCentsOf(entry);
      if (cents == null) return null;
      total += cents;
    }
    return total;
  }

  @override
  List<Object?> get props => [usdToCdf];
}

/// Ce que totalise une sélection de dépenses.
class ExpenseTotals extends Equatable {
  /// Montants par devise d'engagement — jamais additionnés entre eux.
  final MoneyBag bag;
  final int count;

  /// Lecture en dollars du sac, `null` quand elle n'est pas possible (A5).
  final int? usdCents;

  const ExpenseTotals({
    required this.bag,
    required this.count,
    required this.usdCents,
  });

  static const ExpenseTotals zero = ExpenseTotals(
    bag: MoneyBag.empty,
    count: 0,
    usdCents: 0,
  );

  factory ExpenseTotals.of(Iterable<Expense> rows, ExpenseUsdReader reader) {
    final list = rows.toList(growable: false);
    final bag = MoneyBag.sumBy(list, (e) => e.money);
    return ExpenseTotals(
      bag: bag,
      count: list.length,
      usdCents: reader.usdCentsOfBag(bag),
    );
  }

  bool get isEmpty => count == 0;

  /// Montant moyen lu en dollars, `null` sans lecture ou sans dépense.
  int? get averageUsdCents =>
      usdCents == null || count == 0 ? null : (usdCents! / count).round();

  @override
  List<Object?> get props => [bag, count, usdCents];
}

/// Variation en pourcents d'une période sur sa référence (§11, règle 7).
///
/// `null` quand la référence est nulle — une hausse « infinie » n'informe pas
/// — ou quand les deux totaux ne se comparent pas : sans lecture en dollars,
/// seule une paire mono-devise **identique** des deux côtés se compare.
int? expenseVariationPercent(ExpenseTotals current, ExpenseTotals reference) {
  int? now = current.usdCents;
  int? before = reference.usdCents;
  if (now == null || before == null) {
    final a = current.bag.soleEntry;
    final b = reference.bag.soleEntry;
    if (a == null || b == null || a.currency != b.currency) return null;
    now = a.amountInCents;
    before = b.amountInCents;
  }
  if (before <= 0) return null;
  return ((now - before) * 100 / before).round();
}
