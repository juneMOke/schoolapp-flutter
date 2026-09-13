import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';

/// Une somme telle que l'écran la dit : la lecture en dollars quand elle est
/// possible ([primary]), et la paire brute qui la double ([pair]) dès qu'une
/// autre devise que le dollar s'y mêle. Sans lecture, la paire seule.
typedef ExpenseReading = ({String primary, String? pair});

/// L'écriture des montants du module — une façade sur `MoneyFormat`, pour que
/// la doctrine bi-devise (§12) se lise à l'appel : un montant dans sa devise,
/// une **lecture** en dollars, une **paire** jamais additionnée.
abstract final class ExpenseMoneyText {
  /// Le montant d'une dépense, dans sa devise d'engagement.
  static String of(Expense expense) =>
      MoneyFormat.format(Money(expense.amountInCents, expense.currency));

  /// Une lecture en dollars (des centimes de dollar).
  static String usd(int cents) =>
      MoneyFormat.format(Money(cents, CurrencyCode.usd));

  /// La forme courte des étiquettes de graphique.
  static String usdCompact(int cents) =>
      MoneyFormat.compact(Money(cents, CurrencyCode.usd));

  /// « 1 864,00 $ + 3 570 000 FC » — la paire brute, jamais additionnée.
  static String pair(MoneyBag bag) =>
      bag.entries.map(MoneyFormat.format).join(' + ');

  /// Une ligne par devise, pour les cartes qui empilent leurs montants.
  static List<String> lines(MoneyBag bag) =>
      bag.entries.map(MoneyFormat.format).toList(growable: false);

  /// La lecture d'un total, doublée de sa paire quand elle convertit : le
  /// chiffre converti n'est jamais le seul lu (F9).
  static ExpenseReading reading(ExpenseTotals totals) {
    final usdCents = totals.usdCents;
    if (usdCents == null) return (primary: pair(totals.bag), pair: null);
    final converts = totals.bag.currencies.any(showsUsdEquivalent);
    return (primary: usd(usdCents), pair: converts ? pair(totals.bag) : null);
  }

  /// Le taux nommé, côté franc : « 2 800 FC » pour un dollar.
  static String rate(ExchangeRate rate) => MoneyFormat.format(
    Money((rate.rateMicros / (ExchangeRate.scale ~/ 100)).round(), rate.quote),
  );

  /// La devise porte-t-elle un équivalent à afficher sous le montant ?
  /// Un dollar converti en dollar n'apprend rien (spec §5, colonne 3).
  static bool showsUsdEquivalent(String currency) =>
      CurrencyCode.normalize(currency) != CurrencyCode.usd;
}
