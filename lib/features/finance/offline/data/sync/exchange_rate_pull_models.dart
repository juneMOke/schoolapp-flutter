import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/local/exchange_rate_local_model.dart';

/// Un point de la série des taux, tel que le serveur le sert.
///
/// ⚠️ **Les noms sont ceux du contrat, et ils sont en français** :
/// `devisePivot`, `deviseRecue`, `taux`, `tolerancePourcent`,
/// `enVigueurDepuis`. Les deviner en anglais aurait produit une lecture
/// silencieusement vide — le mode de panne qui a déjà coûté cinq champs sur les
/// réductions.
class ExchangeRatePullDto {
  /// La devise de la **créance**.
  final String devisePivot;

  /// La devise réellement tendue au guichet.
  final String deviseRecue;

  /// Combien d'unités de [deviseRecue] pour UNE unité de [devisePivot].
  final double taux;

  /// Bande admise autour de ce taux, en **pourcent** (2.00 = 2 %), gelée avec
  /// lui.
  final double? tolerancePourcent;

  final String enVigueurDepuis;

  const ExchangeRatePullDto({
    required this.devisePivot,
    required this.deviseRecue,
    required this.taux,
    this.tolerancePourcent,
    required this.enVigueurDepuis,
  });

  /// Lecture **tolérante** : un point illisible s'écarte, il ne fait pas tomber
  /// la série. Une lecture ne remonte jamais d'erreur, et perdre toute la série
  /// à cause d'une ligne éteindrait la bascule de tout le guichet.
  static ExchangeRatePullDto? tryFrom(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final pivot = (raw['devisePivot'] as String?)?.trim() ?? '';
    final recue = (raw['deviseRecue'] as String?)?.trim() ?? '';
    final taux = (raw['taux'] as num?)?.toDouble();
    final depuis = (raw['enVigueurDepuis'] as String?)?.trim() ?? '';
    if (pivot.isEmpty || recue.isEmpty || taux == null || depuis.isEmpty) {
      return null;
    }
    return ExchangeRatePullDto(
      devisePivot: pivot,
      deviseRecue: recue,
      taux: taux,
      tolerancePourcent: (raw['tolerancePourcent'] as num?)?.toDouble(),
      enVigueurDepuis: depuis,
    );
  }

  /// La ligne de cache, prête pour `ref_exchange_rates`.
  ///
  /// Deux conversions, et chacune a sa raison : le taux passe en **micro-unités
  /// entières** (le serveur le stocke en `numeric(18,6)` ; un flottant qui
  /// traverserait la couche métier arrondirait de l'argent), et la tolérance
  /// passe du **pourcent** aux **points de base** — 2,00 % devient 200, sans
  /// virgule à traîner.
  ExchangeRateLocalModel? toLocalModel({
    required String schoolId,
    required int syncedAt,
  }) {
    final micros = (taux * ExchangeRate.scale).round();
    if (micros <= 0) return null;
    final base = CurrencyCode.normalize(devisePivot);
    final quote = CurrencyCode.normalize(deviseRecue);
    if (base == quote) return null;
    return ExchangeRateLocalModel(
      schoolId: schoolId,
      base: base,
      quote: quote,
      effectiveFrom: enVigueurDepuis,
      rateMicros: micros,
      divergenceBandBp: tolerancePourcent == null
          ? null
          : (tolerancePourcent! * 100).round(),
      syncedAt: syncedAt,
    );
  }
}
