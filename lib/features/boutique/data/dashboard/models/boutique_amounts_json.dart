import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

/// `[{ "amount": 2000, "currency": "USD" }]` ⇄ [MoneyBag].
///
/// Le même tableau revient sur le top des articles et sur chaque élève : une
/// seule lecture, pour qu'une entrée malformée soit traitée pareil partout.
abstract final class BoutiqueAmountsJson {
  /// Une entrée illisible est **écartée**, jamais lue comme zéro : un zéro
  /// afficherait « 0,00 $ » pour un montant que personne n'a vu.
  static MoneyBag fromJson(Object? raw) => MoneyBag.of([
    for (final entry in (raw is List ? raw : const []))
      if (entry is Map<String, dynamic> &&
          entry['amount'] is num &&
          entry['currency'] is String)
        Money.parse(
          (entry['amount'] as num).toInt(),
          entry['currency'] as String,
        ),
  ]);

  static List<Map<String, dynamic>> toJson(MoneyBag bag) => [
    for (final money in bag.entries)
      {'amount': money.amountInCents, 'currency': money.currency},
  ];
}
