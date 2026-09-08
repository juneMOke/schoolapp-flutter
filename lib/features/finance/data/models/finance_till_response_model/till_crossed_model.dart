import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_rate_micros.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_crossed.dart';

/// Miroir de `TillCurrencyAmountDto` — un montant qui porte sa devise.
class TillCurrencyAmountModel {
  final String currency;
  final int amount;

  const TillCurrencyAmountModel({required this.currency, required this.amount});

  factory TillCurrencyAmountModel.fromJson(Map<String, dynamic> json) {
    return TillCurrencyAmountModel(
      // Normalisée, jamais refusée : même règle que partout dans la caisse.
      currency: ((json['currency'] as String?) ?? '').trim().toUpperCase(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currency': currency,
    'amount': amount,
  };

  TillCurrencyAmount toEntity() =>
      TillCurrencyAmount(currency: currency, amount: amount);
}

/// Miroir de `TillCrossedDto` — les paiements croisés de la fenêtre.
class TillCrossedModel {
  final int count;
  final List<TillCurrencyAmountModel> amounts;

  /// Les taux, déjà convertis en micro-unités à la lecture.
  final List<int> rateMicros;

  const TillCrossedModel({
    required this.count,
    required this.amounts,
    required this.rateMicros,
  });

  /// **Bloc absent vaut « aucun croisement »**, et c'est la seule tolérance que
  /// ce modèle s'accorde. Le croisement est une **lecture** — un encart qui
  /// explique un écart de caisse — pas un chiffre du tiroir : son absence coûte
  /// une explication, jamais un montant faux. Le contraste est voulu avec
  /// `encaisse[]`, dont l'absence lève.
  static TillCrossedModel fromJsonOrEmpty(Object? raw) {
    if (raw is! Map<String, dynamic>) return const TillCrossedModel.empty();
    return TillCrossedModel(
      count: (raw['count'] as num?)?.toInt() ?? 0,
      amounts: [
        for (final entry in (raw['amounts'] as List<dynamic>? ?? const []))
          if (entry is Map<String, dynamic>)
            TillCurrencyAmountModel.fromJson(entry),
      ],
      rateMicros: _ratesToMicros(raw['rates']),
    );
  }

  /// Les taux lisibles, dans l'ordre où le serveur les a triés.
  static List<int> _ratesToMicros(Object? raw) {
    if (raw is! List) return const [];
    final micros = <int>[];
    for (final entry in raw) {
      final value = tillRateToMicros(entry);
      if (value != null) micros.add(value);
    }
    return micros;
  }

  const TillCrossedModel.empty()
    : count = 0,
      amounts = const [],
      rateMicros = const [];

  Map<String, dynamic> toJson() => <String, dynamic>{
    'count': count,
    'amounts': [for (final amount in amounts) amount.toJson()],
    'rates': [for (final micros in rateMicros) micros / ExchangeRate.scale],
  };

  TillCrossed toEntity() => TillCrossed(
    count: count,
    amounts: [for (final amount in amounts) amount.toEntity()],
    rateMicros: rateMicros,
  );
}
