import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les mots du tableau de bord qui dépendent de la donnée. Ici et nulle part
/// ailleurs : l'en-tête, l'état vide et le graphique nomment la même fenêtre.
abstract final class BoutiqueDashboardLabels {
  static String periodLabel(DashboardPeriod period, AppLocalizations l10n) =>
      switch (period) {
        DashboardPeriod.today => l10n.boutiqueDashboardPeriodToday,
        DashboardPeriod.sevenDays => l10n.boutiqueDashboardPeriodSevenDays,
        DashboardPeriod.thirtyDays => l10n.boutiqueDashboardPeriodThirtyDays,
      };

  /// « Ventes au comptant sur 7 jours · du 15/10/2026 au 21/10/2026 » — la
  /// fenêtre exacte est toujours écrite.
  static String windowSubtitle(DashboardWindow window, AppLocalizations l10n) =>
      window.isSingleDay
      ? l10n.boutiqueDashboardSubtitleToday(formatLocalDay(window.to))
      : l10n.boutiqueDashboardSubtitleRange(
          window.dayCount,
          formatLocalDay(window.from),
          formatLocalDay(window.to),
        );

  static String emptyTitle(DashboardWindow window, AppLocalizations l10n) =>
      window.isSingleDay
      ? l10n.boutiqueDashboardEmptyTitleToday
      : l10n.boutiqueDashboardEmptyTitleRange(window.dayCount);

  /// « 7 h » pour une heure, « 15/10 » pour un jour.
  static String bucketLabel(
    BoutiqueStatsBucket bucket,
    StatsGranularity granularity,
    AppLocalizations l10n,
  ) {
    final hour = bucket.hour;
    if (granularity == StatsGranularity.hour && hour != null) {
      return l10n.boutiqueDashboardHourLabel(hour);
    }
    final day = bucket.day;
    if (day == null) return bucket.key;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(day.day)}/${two(day.month)}';
  }

  /// « 20/10/2026 18:05 » **à l'heure de l'école** — la date d'une photo hors
  /// ligne doit se lire dans le même temps que la fenêtre qu'elle montre.
  static String schoolDateTime(DateTime instant) {
    final wall = SchoolTime.wallClock(instant);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${formatLocalDay(wall)} ${two(wall.hour)}:${two(wall.minute)}';
  }

  /// Un montant par devise, l'un sous l'autre — jamais additionnés.
  static List<String> moneyLines(Iterable<Money> amounts) => [
    for (final amount in amounts) MoneyFormat.format(amount),
  ];

  static String moneyInline(Iterable<Money> amounts) =>
      moneyLines(amounts).join(' · ');
}
