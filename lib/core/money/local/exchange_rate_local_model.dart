import 'package:school_app_flutter/core/money/exchange_rate.dart';

/// Une ligne de `ref_exchange_rates` — le taux de guichet tel qu'il dort en
/// local.
///
/// Cache référentiel : écrit par le pull, lu par le guichet. **Rien ne s'écrit
/// jamais d'ici vers le serveur** — un taux se paramètre côté direction.
class ExchangeRateLocalModel {
  final String schoolId;

  /// Devise de la **créance** — le pivot.
  final String base;

  /// Devise **reçue** au guichet.
  final String quote;

  /// ISO-8601, tel que le serveur l'a servi. Conservé en chaîne : la table le
  /// porte dans sa clé primaire, et le reformater ici ferait diverger deux
  /// écritures du même instant.
  final String effectiveFrom;

  /// `taux × 1 000 000`. Entier, jamais un flottant (cf. [ExchangeRate]).
  final int rateMicros;

  /// Bande de divergence en points de base. `null` = non communiquée.
  final int? divergenceBandBp;

  final String? setBy;
  final int syncedAt;

  const ExchangeRateLocalModel({
    required this.schoolId,
    required this.base,
    required this.quote,
    required this.effectiveFrom,
    required this.rateMicros,
    this.divergenceBandBp,
    this.setBy,
    this.syncedAt = 0,
  });

  factory ExchangeRateLocalModel.fromMap(Map<String, Object?> map) =>
      ExchangeRateLocalModel(
        schoolId: (map['school_id'] as String?) ?? '',
        base: (map['base'] as String?) ?? '',
        quote: (map['quote'] as String?) ?? '',
        effectiveFrom: (map['effective_from'] as String?) ?? '',
        rateMicros: (map['rate_micros'] as num?)?.toInt() ?? 0,
        divergenceBandBp: (map['divergence_band_bp'] as num?)?.toInt(),
        setBy: map['set_by'] as String?,
        syncedAt: (map['synced_at'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'school_id': schoolId,
    'base': base,
    'quote': quote,
    'effective_from': effectiveFrom,
    'rate_micros': rateMicros,
    'divergence_band_bp': divergenceBandBp,
    'set_by': setBy,
    'synced_at': syncedAt,
  };

  /// Le taux utilisable, `null` quand la ligne est inexploitable.
  ///
  /// Trois refus, et ils rendent tous `null` plutôt qu'une exception : une
  /// **date illisible** (on ne sait pas quand ce taux vaut, donc on ne
  /// l'applique jamais), un **taux nul ou négatif** (il diviserait ou
  /// inverserait de l'argent), une **devise vide**. Le grand-livre local porte
  /// des lignes sales, et une lecture ne remonte jamais d'erreur : mieux vaut
  /// « pas de taux » — qui éteint la bascule au guichet — qu'un taux inventé.
  ExchangeRate? toEntity() {
    final moment = DateTime.tryParse(effectiveFrom);
    if (moment == null) return null;
    if (rateMicros <= 0) return null;
    if (base.trim().isEmpty || quote.trim().isEmpty) return null;
    return ExchangeRate.parse(
      base: base,
      quote: quote,
      rateMicros: rateMicros,
      effectiveFrom: moment,
      divergenceBandBp: divergenceBandBp,
    );
  }
}
