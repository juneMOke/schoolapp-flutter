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
abstract final class RevenueSeries {
  static List<BoutiqueStatsBucket> visible(
    List<BoutiqueStatsBucket> buckets,
    StatsGranularity granularity,
  ) {
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

  /// L'index de la barre « en cours » — aujourd'hui, ou l'heure qu'il est —,
  /// `-1` si elle n'est pas dessinée.
  static int currentIndex(
    List<BoutiqueStatsBucket> visible,
    String currentKey,
  ) => visible.indexWhere((bucket) => bucket.key == currentKey);
}
