import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/school_year_progress.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/banner/calendar_banner_parts.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/current_year_hero_parts.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/current_year_hero_tiles.dart';
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

  /// [CalendarPhase.inForce] ou, sans année en vigueur, [CalendarPhase.draft]
  /// (décision B : le brouillon de l'année en cours prend le bandeau, en
  /// terre cuite, avec l'avis « pas encore publié »).
  final CalendarPhase phase;

  /// « Publier » (brouillon, droit de publier, en ligne) ; `null` : absent.
  final VoidCallback? onPublish;

  const CurrentYearHero({
    super.key,
    required this.calendar,
    required this.elements,
    required this.today,
    required this.rhythm,
    required this.onOpen,
    this.phase = CalendarPhase.inForce,
    this.onPublish,
  });

  bool get _draft => phase == CalendarPhase.draft;

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
    final tiles = progress == null
        ? null
        : CurrentYearHeroTiles(progress: progress);
    return KubaBanner(
      stripe: false,
      colors: _draft
          ? calendarBannerColors(CalendarPhase.draft)
          : const [
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
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                if (onPublish case final publish?) HeroPublishButton(publish),
                HeroOpenButton(onOpen),
              ],
            ),
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
    final updated = calendar.updatedAt;
    final dates = [
      CalendarLabels.yearRange(context, calendar.startDate, calendar.endDate),
      if (_draft && updated != null)
        l10n.schoolCalendarModifiedLine(
          CalendarDays.between(
            CalendarDays.of(updated.toLocal()),
            today,
          ).clamp(0, 1 << 20),
        )
      else if (!_draft && published != null)
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
            if (_draft)
              const CalendarStatusPill(CalendarPhase.draft)
            else
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
        if (_draft) ...[
          const SizedBox(height: AppSpacing.sm),
          HeroDraftNotice(l10n.schoolCalendarDraftNotPublished),
        ],
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
}
