import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/school_year_progress.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/banner/calendar_banner_parts.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/banner/calendar_banner_tiles.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/year_progress_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau replié d'un calendrier ouvert (spec §4.6 B, maquette
/// `CalDetail` sous 600 ou en fenêtre basse) : le titre et le statut, une
/// ligne de dates, une ligne « Cadre national · n nationaux · n internes »,
/// l'avancement, puis Période et Prochaine échéance en texte — côte à côte
/// avec [twoColumns].
class CalendarBannerCompactBody extends StatelessWidget {
  final SchoolCalendar calendar;
  final CalendarPhase phase;
  final SchoolYearProgress? progress;
  final int nationalCount;
  final int schoolCount;
  final bool twoColumns;

  const CalendarBannerCompactBody({
    super.key,
    required this.calendar,
    required this.phase,
    required this.progress,
    required this.nationalCount,
    required this.schoolCount,
    required this.twoColumns,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.calendarHeroMuted,
    );
    final framework = calendar.hasFramework
        ? l10n.schoolCalendarNationalFramework
        : l10n.schoolCalendarFrameworkAwaited;
    final progress = this.progress;
    final lines = progress == null
        ? null
        : calendarBannerLines(context, progress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.schoolCalendarTitleYear(calendar.yearLabel),
              style: AppTypography.calendarDetailTitleCompact.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
            CalendarStatusPill(phase),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${CalendarLabels.dayWithYear(context, calendar.startDate)} → '
          '${CalendarLabels.dayWithYear(context, calendar.endDate)} · '
          '${calendarWeeksLabel(l10n, calendar)}',
          style: muted,
        ),
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    calendar.hasFramework
                        ? Icons.lock_outline
                        : Icons.schedule_outlined,
                    size: AppTypography.bodySmall.fontSize,
                    color: AppColors.calendarHeroMuted,
                  ),
                ),
              ),
              TextSpan(
                text: [
                  framework,
                  l10n.schoolCalendarCounts(nationalCount, schoolCount),
                ].join(' · '),
              ),
            ],
          ),
          style: muted,
        ),
        if (progress != null && lines != null) ...[
          const SizedBox(height: AppSpacing.sm),
          YearProgressBar(
            progress: progress,
            startDate: calendar.startDate,
            endDate: calendar.endDate,
            markers: const [],
            legend: false,
            maxWidth: null,
          ),
          const SizedBox(height: AppSpacing.sm),
          _lines(l10n, lines),
        ],
      ],
    );
  }

  Widget _lines(AppLocalizations l10n, (String, String) lines) {
    final period = CalendarBannerTextLine(
      label: l10n.schoolCalendarPeriod,
      value: lines.$1,
    );
    final next = CalendarBannerTextLine(
      label: l10n.schoolCalendarNextDeadline,
      value: lines.$2,
    );
    if (!twoColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          period,
          const SizedBox(height: AppSpacing.xs),
          next,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: period),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: next),
      ],
    );
  }
}
