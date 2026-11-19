import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_tile.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/school_year_progress.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau d'une année (spec Calendrier §4.6 B) : titre, statut, dates,
/// cadre, l'avancement « Semaine n / N », puis Période, En ce moment et
/// Prochaine échéance (CAL-R14). Hors de l'année, ni avancement ni tuiles.
class CalendarYearBanner extends StatelessWidget {
  final SchoolCalendar calendar;
  final CalendarPhase phase;
  final List<CalendarElement> elements;
  final DateTime today;
  final PeriodRhythm? rhythm;
  final String eyebrow;
  final int nationalCount;
  final int schoolCount;
  final Widget? trailing;

  const CalendarYearBanner({
    super.key,
    required this.calendar,
    required this.phase,
    required this.elements,
    required this.today,
    required this.rhythm,
    required this.eyebrow,
    required this.nationalCount,
    required this.schoolCount,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = SchoolYearProgress.compute(
      startDate: calendar.startDate,
      endDate: calendar.endDate,
      today: today,
      elements: elements,
      rhythm: rhythm,
    );
    final onDark = AppTypography.bodySmall.copyWith(
      color: AppColors.textOnDark,
    );
    return KubaBanner(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.kubaBannerOn,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                calendar.yearLabel,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
              _Pill(CalendarLabels.phase(l10n, phase)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CalendarLabels.range(context, calendar.startDate, calendar.endDate),
            style: onDark,
          ),
          Text(
            [
              calendar.hasFramework
                  ? l10n.schoolCalendarFrameworkIntegrated
                  : l10n.schoolCalendarFrameworkAwaited,
              l10n.schoolCalendarCounts(nationalCount, schoolCount),
            ].join(' · '),
            style: onDark,
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.schoolCalendarWeek(progress.week, progress.weekCount),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: AppRadius.brSm,
              child: LinearProgressIndicator(
                value: progress.ratio,
                minHeight: AppSpacing.sm,
                color: AppColors.orDoux,
                backgroundColor: AppColors.kubaBannerOn.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                KubaBannerTile(
                  label: l10n.schoolCalendarPeriod,
                  values: [
                    CalendarLabels.period(l10n, progress.currentPeriod) ??
                        l10n.schoolCalendarOutOfPeriod,
                  ],
                ),
                KubaBannerTile(
                  label: l10n.schoolCalendarNow,
                  values: [
                    if (progress.happeningNow.isEmpty)
                      l10n.schoolCalendarNormalClasses
                    else
                      for (final e in progress.happeningNow.take(2)) e.title,
                  ],
                ),
                KubaBannerTile(
                  label: l10n.schoolCalendarNextDeadline,
                  values: [progress.nextDeadline?.title ?? '—'],
                  detail: progress.daysUntilNextDeadline == null
                      ? null
                      : l10n.schoolCalendarInDays(
                          progress.daysUntilNextDeadline!,
                        ),
                ),
              ],
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: BoxDecoration(
      borderRadius: AppRadius.brSm,
      border: Border.all(color: AppColors.kubaBannerOn),
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall.copyWith(color: AppColors.kubaBannerOn),
    ),
  );
}
