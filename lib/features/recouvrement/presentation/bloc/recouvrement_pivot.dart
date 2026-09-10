import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// Ramener un sac multi-devise à **une** devise — pour comparer et pour
/// ordonner, jamais pour afficher.
///
/// C'est la seule opération du module qui fasse intervenir un cours. Elle est
/// dite ici, une fois, parce que deux écrans s'en servent : la simulation du
/// tableau de bord (« a versé moins que le plancher ») et le contrôle nominatif
/// (« a payé au moins… », et le taux d'une ligne mixte).
///
/// ⚠️ **`null` veut dire « on ne sait pas », et jamais zéro.** Sans cours, un
/// sac qui porte une autre devise n'est pas convertible : rendre `0` ferait
/// entrer ou sortir des élèves d'une liste de relance sur un chiffre inventé.
/// L'appelant renonce — il ne devine pas.
class RecouvrementPivot {
  const RecouvrementPivot._();

  /// [bag] ramené en [currency], en centimes. `null` dès qu'une entrée ne s'y
  /// convertit pas.
  ///
  /// Un sac vide vaut `0` : il n'y a rien à convertir, et ce zéro-là est exact.
  static int? inCurrency(MoneyBag bag, String currency, ExchangeRate? rate) {
    var total = 0;
    for (final entry in bag.entries) {
      if (entry.currency == currency) {
        total += entry.amountInCents;
        continue;
      }
      final converted = convert(entry, currency, rate);
      if (converted == null) return null;
      total += converted;
    }
    return total;
  }

  /// Le cours dollar → franc en vigueur, ou `null` si l'école n'en a posé
  /// aucun.
  ///
  /// Le sens contraire rend `null` plutôt qu'un taux retourné : l'inverse d'un
  /// taux arrondi n'est pas le taux inverse, et ce nombre sert des arbitrages.
  static ExchangeRate? dollarInFrancs(List<ExchangeRate> rates) =>
      ExchangeRates.at(
        rates,
        base: CurrencyCode.usd,
        quote: CurrencyCode.cdf,
        moment: DateTime.now(),
      );

  /// Convertit **pour trier**, jamais pour afficher. `null` quand aucun cours ne
  /// relie les deux devises.
  static int? convert(Money amount, String target, ExchangeRate? rate) {
    if (amount.currency == target) return amount.amountInCents;
    if (rate == null) return null;
    if (rate.base == amount.currency && rate.quote == target) {
      return (amount.amountInCents * rate.rateMicros) ~/ ExchangeRate.scale;
    }
    if (rate.quote == amount.currency && rate.base == target) {
      if (rate.rateMicros == 0) return null;
      return (amount.amountInCents * ExchangeRate.scale) ~/ rate.rateMicros;
    }
    return null;
  }
}
