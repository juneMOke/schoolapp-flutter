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
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/banner/calendar_banner_compact.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/banner/calendar_banner_parts.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/banner/calendar_banner_tiles.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/year_progress_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau d'un calendrier ouvert (spec §4.6 B, maquette `CalDetail`) :
/// médaillon, « Calendrier 2025-2026 » et son statut, les dates et le nombre
/// de semaines, le cadre national, les tuiles nationaux / internes, puis dans
/// l'année l'avancement, Période et Prochaine échéance. Teinte selon la
/// phase. Pas de surtitre : la barre du haut nomme la page.
///
/// [compact] (téléphone, fenêtre basse) : le titre et le statut, une ligne de
/// dates, une ligne « Cadre national · n nationaux · n internes »,
/// l'avancement, puis Période et Prochaine échéance en texte — côte à côte
/// avec [twoColumns] (fenêtre basse assez large).
class CalendarYearBanner extends StatelessWidget {
  final SchoolCalendar calendar;
  final CalendarPhase phase;
  final List<CalendarElement> elements;
  final DateTime today;
  final PeriodRhythm? rhythm;
  final int nationalCount;
  final int schoolCount;
  final bool compact;
  final bool twoColumns;

  const CalendarYearBanner({
    super.key,
    required this.calendar,
    required this.phase,
    required this.elements,
    required this.today,
    required this.rhythm,
    required this.nationalCount,
    required this.schoolCount,
    this.compact = false,
    this.twoColumns = false,
  });

  static const _infoMin = AppDimensions.calendarHeroInfoMinWidth;

  @override
  Widget build(BuildContext context) {
    final progress = SchoolYearProgress.compute(
      startDate: calendar.startDate,
      endDate: calendar.endDate,
      today: today,
      elements: elements,
      rhythm: rhythm,
    );
    return KubaBanner(
      stripe: false,
      colors: calendarBannerColors(phase),
      child: compact
          ? CalendarBannerCompactBody(
              calendar: calendar,
              phase: phase,
              progress: progress,
              nationalCount: nationalCount,
              schoolCount: schoolCount,
              twoColumns: twoColumns,
            )
          : _full(context, progress),
    );
  }

  Widget _full(BuildContext context, SchoolYearProgress? progress) {
    final l10n = AppLocalizations.of(context)!;
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.calendarHeroMuted,
    );
    final title = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.schoolCalendarTitleYear(calendar.yearLabel),
          style: AppTypography.calendarDetailTitle.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        CalendarStatusPill(phase),
      ],
    );
    final dates = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${CalendarLabels.weekdayWithYear(context, calendar.startDate)} → '
          '${CalendarLabels.weekdayWithYear(context, calendar.endDate)} · '
          '${calendarWeeksLabel(l10n, calendar)}',
          style: muted,
        ),
        CalendarFrameworkChip(integrated: calendar.hasFramework),
      ],
    );
    final counts = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        CalendarCountTile(
          value: nationalCount,
          label: l10n.schoolCalendarNationalCountLabel(nationalCount),
          icon: Icons.lock_outline,
        ),
        CalendarCountTile(
          value: schoolCount,
          label: l10n.schoolCalendarInternalCountLabel(schoolCount),
          icon: Icons.edit_outlined,
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final head = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CalendarBannerMedallion(),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: AppSpacing.xs),
                      dates,
                    ],
                  ),
                ),
              ],
            );
            if (constraints.maxWidth < _infoMin * 2) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  head,
                  const SizedBox(height: AppSpacing.md),
                  counts,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: head),
                const SizedBox(width: AppSpacing.md),
                counts,
              ],
            );
          },
        ),
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.md),
          _progressRow(context, progress),
        ],
      ],
    );
  }

  Widget _progressRow(BuildContext context, SchoolYearProgress progress) {
    final l10n = AppLocalizations.of(context)!;
    final (period, next) = calendarBannerLines(context, progress);
    final bar = YearProgressBar(
      progress: progress,
      startDate: calendar.startDate,
      endDate: calendar.endDate,
      markers: const [],
      legend: false,
      maxWidth: null,
    );
    final tiles = [
      KubaBannerTile(
        dense: true,
        label: l10n.schoolCalendarPeriod,
        values: [period],
      ),
      KubaBannerTile(
        dense: true,
        label: l10n.schoolCalendarNextDeadline,
        values: [next],
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _infoMin * 2) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              bar,
              for (final tile in tiles) ...[
                const SizedBox(height: AppSpacing.sm),
                tile,
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Align(alignment: Alignment.centerLeft, child: bar),
              ),
              for (final tile in tiles) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(child: tile),
              ],
            ],
          ),
        );
      },
    );
  }
}
