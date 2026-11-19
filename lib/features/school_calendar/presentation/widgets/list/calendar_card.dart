import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class CalendarCard extends StatelessWidget {
  final SchoolCalendar calendar;
  final CalendarPhase phase;
  final VoidCallback onOpen;

  const CalendarCard({
    super.key,
    required this.calendar,
    required this.phase,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final published = calendar.publishedAt;
    return EteeloActivatable(
      onActivate: onOpen,
      semanticLabel: l10n.schoolCalendarTitleYear(calendar.yearLabel),
      builder: (context, highlight) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: highlight.any ? AppColors.terreCuite : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(calendar.yearLabel, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CalendarLabels.phase(l10n, phase),
              style: AppTypography.labelMedium.copyWith(
                color: phase == CalendarPhase.draft
                    ? AppColors.terreCuiteInk
                    : AppColors.bleuArdoise,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CalendarLabels.range(
                context,
                calendar.startDate,
                calendar.endDate,
              ),
              style: AppTypography.bodySmall,
            ),
            Text(
              calendar.hasFramework
                  ? l10n.schoolCalendarFrameworkIntegrated
                  : l10n.schoolCalendarFrameworkAwaited,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (published != null)
              Text(
                l10n.schoolCalendarPublishedOn(
                  CalendarLabels.day(context, published),
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
