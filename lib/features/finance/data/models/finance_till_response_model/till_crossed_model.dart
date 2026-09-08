import 'package:school_app_flutter/core/money/exchange_rate.dart';
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
      final value = _toMicros(entry);
      if (value != null) micros.add(value);
    }
    return micros;
  }

  const TillCrossedModel.empty()
    : count = 0,
      amounts = const [],
      rateMicros = const [];

  /// Un taux passe en **micro-unités**, comme partout ailleurs dans le socle
  /// monétaire : un flottant qui traverse la couche métier finit par arrondir de
  /// l'argent. Même conversion que le pull des taux de change
  /// (`exchange_rate_pull_models.dart`), pour que les deux chemins ne divergent
  /// pas d'un centième.
  ///
  /// Un taux nul, négatif ou illisible est **écarté** plutôt que replié sur zéro :
  /// « au taux de 0 » se lirait comme une conversion observée.
  static int? _toMicros(Object? raw) {
    if (raw is! num) return null;
    final micros = (raw * ExchangeRate.scale).round();
    return micros > 0 ? micros : null;
  }

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
