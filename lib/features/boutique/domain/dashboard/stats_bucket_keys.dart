import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';

/// Les clés de seau **telles que le serveur les écrit** : `2026-10-15` pour un
/// jour, `2026-10-21T07` pour une heure.
///
/// Une seule fabrique pour les deux usages — ranger une vente provisoire dans
/// son seau, et créer la série d'une devise que le serveur n'a pas encore vue —
/// sans quoi les deux finiraient par ne plus s'accorder sur un zéro.
abstract final class StatsBucketKeys {
  /// Le seau de [instant], lu **à Kinshasa**.
  static String of(DateTime instant, StatsGranularity granularity) {
    final wall = SchoolTime.wallClock(instant);
    final day = dayKey(wall);
    return granularity == StatsGranularity.hour
        ? '${day}T${_two(wall.hour)}'
        : day;
  }

  /// La série dense de [window] : un seau par jour, ou 24 pour une journée
  /// découpée à l'heure.
  static List<String> denseKeys(
    DashboardWindow window,
    StatsGranularity granularity,
  ) {
    if (granularity == StatsGranularity.hour) {
      final day = dayKey(window.from);
      return [for (var h = 0; h < 24; h++) '${day}T${_two(h)}'];
    }
    return [
      for (var i = 0; i < window.dayCount; i++)
        dayKey(
          DateTime(window.from.year, window.from.month, window.from.day + i),
        ),
    ];
  }

  /// `YYYY-MM-DD` — la forme d'un seau de jour, et celle des `from` / `to`
  /// de la requête.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
