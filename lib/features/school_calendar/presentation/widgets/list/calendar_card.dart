import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/calendar_summary.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendar_card_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une carte de calendrier (spec §4.6 K, maquette `CalCard`) : médaillon,
/// l'année et ses dates, les pastilles, la répartition par nature, puis
/// « Modifié il y a … » ou « Publié le … » et le nombre d'éléments internes.
/// Le menu « ⋮ » propose « Dupliquer pour … » quand c'est possible (R8).
class CalendarCard extends StatelessWidget {
  final SchoolCalendar calendar;
  final CalendarPhase phase;
  final CalendarSummary summary;
  final DateTime today;
  final VoidCallback onOpen;

  /// `null` : pas de menu (pas le droit, hors ligne, année suivante prise).
  final VoidCallback? onDuplicate;

  const CalendarCard({
    super.key,
    required this.calendar,
    required this.phase,
    required this.summary,
    required this.today,
    required this.onOpen,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tint = CalendarCardTint.of(phase);
    final faded =
        phase == CalendarPhase.archived || phase == CalendarPhase.ended;
    final card = EteeloActivatable(
      onActivate: onOpen,
      semanticLabel: l10n.schoolCalendarTitleYear(calendar.yearLabel),
      builder: (context, highlight) => ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tint.surface, AppColors.surfaceRaised],
              stops: const [0, 0.7],
            ),
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: highlight.any ? AppColors.terreCuite : tint.border,
            ),
            boxShadow: AppElevation.shadowKpi,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: AppDimensions.calendarCardAccent,
                child: ColoredBox(color: tint.accent),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _title(context, tint),
                    const SizedBox(height: AppSpacing.md - AppSpacing.xs / 2),
                    CalendarCardBadges(
                      calendar: calendar,
                      phase: phase,
                      summary: summary,
                    ),
                    const SizedBox(height: AppSpacing.md - AppSpacing.xs / 2),
                    CalendarNatureBar(summary: summary, faded: faded),
                    const SizedBox(height: AppSpacing.md - AppSpacing.xs / 2),
                    Text(
                      _foot(context),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final duplicate = onDuplicate;
    final next = calendar.nextYearLabel;
    if (duplicate == null || next == null) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: PopupMenuButton<void>(
            tooltip: l10n.schoolCalendarMoreActions,
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            itemBuilder: (_) => [
              PopupMenuItem<void>(
                onTap: duplicate,
                child: Row(
                  children: [
                    const Icon(
                      Icons.copy_outlined,
                      size: AppDimensions.detailMiniIconSize,
                      color: AppColors.bleuArdoise,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(l10n.schoolCalendarDuplicateFor(next)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _title(BuildContext context, CalendarCardTint tint) => Padding(
    // La place du menu « ⋮ ».
    padding: const EdgeInsets.only(right: AppSpacing.xxl),
    child: Row(
      children: [
        Container(
          width: AppDimensions.calendarCardMedallion,
          height: AppDimensions.calendarCardMedallion,
          decoration: BoxDecoration(
            color: tint.accent,
            borderRadius: AppRadius.brMd,
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            size: AppDimensions.calendarCardMedallionIcon,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md - AppSpacing.xs / 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                calendar.yearLabel,
                style: AppTypography.calendarCardYear.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                CalendarLabels.yearRange(
                  context,
                  calendar.startDate,
                  calendar.endDate,
                ),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _foot(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final published = calendar.publishedAt;
    final updated = calendar.updatedAt;
    final when = phase == CalendarPhase.draft || published == null
        ? (updated == null
              ? null
              : l10n.schoolCalendarModifiedAgo(
                  CalendarDays.between(
                    CalendarDays.of(updated.toLocal()),
                    today,
                  ).clamp(0, 1 << 20),
                ))
        : l10n.schoolCalendarPublishedOn(
            CalendarLabels.dayWithYear(context, published),
          );
    return [
      ?when,
      l10n.schoolCalendarSchoolItems(summary.schoolCount),
    ].join(' · ');
  }
}
