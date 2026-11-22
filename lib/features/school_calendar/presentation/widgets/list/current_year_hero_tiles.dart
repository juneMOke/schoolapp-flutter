import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_tile.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/school_year_progress.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/hero_tiles_wrap.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les tuiles du bandeau « Année en cours » : Période (jusqu'au …), En ce
/// moment (+ n autres), Prochaine échéance (dans n jours · date).
class CurrentYearHeroTiles extends StatelessWidget {
  final SchoolYearProgress progress;

  const CurrentYearHeroTiles({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final period = progress.currentPeriod;
    final now = progress.happeningNow;
    final next = progress.nextDeadline;
    final days = progress.daysUntilNextDeadline;
    return HeroTilesWrap(
      children: [
        KubaBannerTile(
          dense: true,
          label: l10n.schoolCalendarPeriod,
          values: [
            CalendarLabels.period(l10n, period) ??
                l10n.schoolCalendarOutOfPeriod,
          ],
          detail: period == null
              ? '—'
              : l10n.schoolCalendarUntil(
                  CalendarLabels.shortDay(context, period.endDate),
                ),
        ),
        KubaBannerTile(
          dense: true,
          label: l10n.schoolCalendarNow,
          values: [
            now.isEmpty ? l10n.schoolCalendarNormalClasses : now.first.title,
          ],
          detail: now.length > 1
              ? l10n.schoolCalendarMoreOthers(now.length - 1)
              : now.isEmpty
              ? null
              : CalendarLabels.dates(context, now.first),
        ),
        KubaBannerTile(
          dense: true,
          label: l10n.schoolCalendarNextDeadline,
          values: [next?.title ?? '—'],
          detail: next == null || days == null
              ? null
              : [
                  l10n.schoolCalendarInDays(days),
                  CalendarLabels.shortDay(context, next.startDate),
                ].join(' · '),
        ),
      ],
    );
  }
}
