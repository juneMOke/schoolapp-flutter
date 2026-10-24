import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les mots du tableau de bord qui dépendent de la donnée. Ici et nulle part
/// ailleurs : l'en-tête, l'état vide et le graphique nomment la même fenêtre.
abstract final class BoutiqueDashboardLabels {
  /// « Ventes au comptant sur 3 jours · du 19/10/2026 au 21/10/2026 » — la
  /// fenêtre exacte est toujours écrite.
  ///
  /// Une journée ne se dit « aujourd'hui » que sous l'onglet du même nom : le
  /// lundi de « Cette semaine » ou une période précise d'un jour passé se
  /// nomment par leur date.
  static String windowSubtitle(
    DashboardWindow window,
    DashboardPeriod period,
    AppLocalizations l10n,
  ) {
    if (!window.isSingleDay) {
      return l10n.boutiqueDashboardSubtitleRange(
        window.dayCount,
        formatLocalDay(window.from),
        formatLocalDay(window.to),
      );
    }
    final day = formatLocalDay(window.to);
    return period == DashboardPeriod.today
        ? l10n.boutiqueDashboardSubtitleToday(day)
        : l10n.boutiqueDashboardSubtitleDay(day);
  }

  static String emptyTitle(
    DashboardWindow window,
    DashboardPeriod period,
    AppLocalizations l10n,
  ) {
    if (!window.isSingleDay) {
      return l10n.boutiqueDashboardEmptyTitleRange(window.dayCount);
    }
    return period == DashboardPeriod.today
        ? l10n.boutiqueDashboardEmptyTitleToday
        : l10n.boutiqueDashboardEmptyTitleDay(formatLocalDay(window.to));
  }

  /// « 7 h » pour une heure, « 15/10 » pour un jour, « 10/2026 » pour un mois.
  static String bucketLabel(
    BoutiqueStatsBucket bucket,
    StatsGranularity granularity,
    AppLocalizations l10n,
  ) {
    final hour = bucket.hour;
    if (granularity == StatsGranularity.hour && hour != null) {
      return l10n.boutiqueDashboardHourLabel(hour);
    }
    final month = bucket.month;
    if (granularity == StatsGranularity.day && month != null) {
      return '${month.month.toString().padLeft(2, '0')}/${month.year}';
    }
    final day = bucket.day;
    if (day == null) return bucket.key;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(day.day)}/${two(day.month)}';
  }

  /// Un montant par devise, l'un sous l'autre — jamais additionnés.
  static List<String> moneyLines(Iterable<Money> amounts) => [
    for (final amount in amounts) MoneyFormat.format(amount),
  ];

  static String moneyInline(Iterable<Money> amounts) =>
      moneyLines(amounts).join(' · ');
}
