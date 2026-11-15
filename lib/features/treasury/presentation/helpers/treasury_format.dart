import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les montants, heures et devises de la trésorerie, écrits une seule fois.
///
/// Un montant s'écrit toujours **exact** (« 3 450 000 FC ») : sur une surface
/// qu'on rapproche des billets, un format court serait un chiffre faux.
abstract final class TreasuryFormat {
  static String money(int amountInCents, TreasuryCurrency currency) =>
      MoneyFormat.format(Money(amountInCents, currency.code));

  /// « +80,00 $ », « -5 000 FC », « 0 FC » : le signe dit le sens, jamais la
  /// couleur seule.
  static String signedMoney(int amountInCents, TreasuryCurrency currency) {
    final text = money(amountInCents, currency);
    return amountInCents > 0 ? '+$text' : text;
  }

  static String symbol(TreasuryCurrency currency) =>
      MoneyFormat.symbolOf(currency.code);

  static String currencyName(
    AppLocalizations l10n,
    TreasuryCurrency currency,
  ) => switch (currency) {
    TreasuryCurrency.usd => l10n.treasuryCurrencyUsd,
    TreasuryCurrency.cdf => l10n.treasuryCurrencyCdf,
  };

  /// « 17:45 », lu à l'heure de l'école (jamais celle de la tablette).
  static String time(DateTime instant) {
    final wall = SchoolTime.wallClock(instant);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(wall.hour)}:${two(wall.minute)}';
  }
}
