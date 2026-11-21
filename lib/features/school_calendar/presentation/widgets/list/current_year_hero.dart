import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_tile.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/school_year_progress.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/current_year_hero_parts.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/hero_tiles_wrap.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/year_progress_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau « Année en cours » de la liste (spec §4.6 B, maquette
/// `CalCurrentHero`) : l'année, « En vigueur », les dates et qui a publié,
/// l'avancement à repères ; à côté, Période, En ce moment et Prochaine
/// échéance ; enfin « Ouvrir le calendrier », à droite.
class CurrentYearHero extends StatelessWidget {
  final SchoolCalendar calendar;

  /// Les éléments montrés du calendrier : cadre et événements de l'école.
  final List<CalendarElement> elements;
  final DateTime today;
  final PeriodRhythm? rhythm;
  final VoidCallback onOpen;

  const CurrentYearHero({
    super.key,
    required this.calendar,
    required this.elements,
    required this.today,
    required this.rhythm,
    required this.onOpen,
  });

  static const _twoColumnsMin =
      AppDimensions.calendarHeroInfoMinWidth +
      AppSpacing.lg +
      AppDimensions.calendarHeroTilesMinWidth;

  @override
  Widget build(BuildContext context) {
    final progress = SchoolYearProgress.compute(
      startDate: calendar.startDate,
      endDate: calendar.endDate,
      today: today,
      elements: elements,
      rhythm: rhythm,
    );
    final info = _info(context, progress);
    final tiles = progress == null ? null : _tiles(context, progress);
    return KubaBanner(
      stripe: false,
      colors: const [
        AppColors.kubaBannerStart,
        AppColors.kubaBannerMid,
        AppColors.calendarHeroEnd,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (tiles == null) return info;
              if (constraints.maxWidth < _twoColumnsMin) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: AppSpacing.lg),
                    tiles,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: tiles),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: HeroOpenButton(onOpen),
          ),
        ],
      ),
    );
  }

  Widget _info(BuildContext context, SchoolYearProgress? progress) {
    final l10n = AppLocalizations.of(context)!;
    final published = calendar.publishedAt;
    final by = calendar.publishedBy;
    final role = by?.role == null
        ? ''
        : l10n.schoolCalendarActorRole(by!.role!);
    final name = by?.name == null
        ? null
        : role.isEmpty
        ? by!.name!
        : '${by!.name!} ($role)';
    final dates = [
      CalendarLabels.yearRange(context, calendar.startDate, calendar.endDate),
      if (published != null)
        name == null
            ? l10n.schoolCalendarPublishedLine(
                CalendarLabels.dayWithYear(context, published),
              )
            : l10n.schoolCalendarPublishedBy(
                CalendarLabels.dayWithYear(context, published),
                name,
              ),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.schoolCalendarCurrentYear.toUpperCase(),
          style: AppTypography.eyebrow.copyWith(
            color: AppColors.orDoux,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              calendar.yearLabel,
              style: AppTypography.calendarHeroYear.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
            HeroLivePill(CalendarLabels.phase(l10n, CalendarPhase.inForce)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          dates,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.calendarHeroMuted,
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.md + AppSpacing.xs / 2),
          YearProgressBar(
            progress: progress,
            startDate: calendar.startDate,
            endDate: calendar.endDate,
            markers: _periodStarts(),
          ),
        ],
      ],
    );
  }

  /// Le début de chaque sous-période (P1…P4) ; à défaut, de chaque période.
  List<DateTime> _periodStarts() {
    final periods = [
      for (final e in elements)
        if (e.nature == CalendarNature.period) e,
    ];
    final subs = periods.where((e) => e.subPeriodOrder != null).toList();
    return [for (final p in subs.isEmpty ? periods : subs) p.startDate];
  }

  Widget _tiles(BuildContext context, SchoolYearProgress progress) {
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
