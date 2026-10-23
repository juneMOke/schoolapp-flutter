import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';

/// Les barres que le graphique dessine, prises dans la série **dense** du
/// serveur.
///
/// - **Seuls les seaux où l'on a vendu se dessinent** — heure, jour ou mois.
///   C'est la règle de la caisse Finances (`FinanceTillBucketsSection`),
///   tranchée par le porteur : un axe de trente jours dont vingt à zéro
///   noierait les jours de vente. Prix connu : l'axe n'est plus régulier dans
///   le temps, deux barres voisines peuvent être séparées d'un jour ou de six.
/// - Au-delà de [monthlyBeyond] jours, les jours sont **regroupés par mois** —
///   comme la caisse, dont le serveur découpe l'année par mois : le nôtre ne
///   découpe qu'à l'heure ou au jour, et une année jour par jour ferait deux
///   cents barres sans libellé lisible.
abstract final class RevenueSeries {
  /// Deux mois : « Ce mois » et une période précise courte restent au jour.
  static const int monthlyBeyond = 62;

  /// Vrai quand [buckets] se dessine mois par mois.
  static bool isMonthly(
    List<BoutiqueStatsBucket> buckets,
    StatsGranularity granularity,
  ) => granularity == StatsGranularity.day && buckets.length > monthlyBeyond;

  static List<BoutiqueStatsBucket> visible(
    List<BoutiqueStatsBucket> buckets,
    StatsGranularity granularity,
  ) {
    final series = isMonthly(buckets, granularity)
        ? _byMonth(buckets)
        : buckets;
    return [
      for (final bucket in series)
        if (bucket.total > 0) bucket,
    ];
  }

  /// Un seau par mois, dans l'ordre de la série — le premier et le dernier
  /// mois partiels, comme la fenêtre. Un seau illisible est écarté plutôt que
  /// rangé dans un mois au hasard.
  static List<BoutiqueStatsBucket> _byMonth(List<BoutiqueStatsBucket> buckets) {
    final totals = <String, int>{};
    for (final bucket in buckets) {
      final day = bucket.day;
      if (day == null) continue;
      final key = monthKey(day);
      totals[key] = (totals[key] ?? 0) + bucket.total;
    }
    return [
      for (final entry in totals.entries)
        BoutiqueStatsBucket(key: entry.key, total: entry.value),
    ];
  }

  /// `2026-10` — la clé d'un seau de mois, et celle du mois en cours.
  static String monthKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}';

  /// L'index de la barre « en cours » — aujourd'hui, ou l'heure qu'il est —,
  /// `-1` si elle n'est pas dessinée.
  static int currentIndex(
    List<BoutiqueStatsBucket> visible,
    String currentKey,
  ) => visible.indexWhere((bucket) => bucket.key == currentKey);
}
