import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';

/// Les barres que le graphique dessine, prises dans la série **dense** du
/// serveur.
///
/// - Heure par heure : les heures vides **en tête et en queue** sont retirées —
///   le serveur n'a pas à connaître les heures d'ouverture, et 24 barres dont
///   quinze à zéro noieraient la journée. Un creux en pleine journée reste.
/// - Jour par jour : un dimanche est retiré **s'il est vide**. Une école qui
///   vend le dimanche garde sa barre, sans paramètre d'école à inventer.
/// - Au-delà de [monthlyBeyond] jours, les jours sont **regroupés par mois** :
///   le serveur ne découpe qu'à l'heure ou au jour, et une année jour par jour
///   ferait deux cents barres sans libellé lisible.
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
    if (isMonthly(buckets, granularity)) return _byMonth(buckets);
    if (granularity == StatsGranularity.hour) {
      final first = buckets.indexWhere((b) => b.total > 0);
      if (first < 0) return const [];
      final last = buckets.lastIndexWhere((b) => b.total > 0);
      return buckets.sublist(first, last + 1);
    }
    return [
      for (final bucket in buckets)
        if (bucket.total > 0 || bucket.day?.weekday != DateTime.sunday) bucket,
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
