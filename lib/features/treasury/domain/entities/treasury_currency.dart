import 'package:school_app_flutter/core/money/currency_code.dart';

/// La devise d'une caisse. En v1, une caisse par devise, et les montants de
/// deux devises ne s'additionnent ni ne se convertissent jamais (R1).
enum TreasuryCurrency {
  usd(CurrencyCode.usd),
  cdf(CurrencyCode.cdf);

  const TreasuryCurrency(this.code);

  /// Le code ISO, tel qu'il circule sur le fil et tel que `MoneyFormat` le lit.
  final String code;

  /// `null` pour une devise que la trésorerie ne connaît pas : une caisse
  /// inconnue ne doit pas se faire passer pour l'une des deux.
  static TreasuryCurrency? fromCode(String? raw) {
    final code = CurrencyCode.normalize(raw ?? '');
    for (final currency in values) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  /// Le franc s'écrit sans décimales : un montant saisi en francs doit tomber
  /// sur un franc entier (100 centimes).
  bool acceptsCents(int amountInCents) =>
      this == TreasuryCurrency.usd || amountInCents % 100 == 0;
}
