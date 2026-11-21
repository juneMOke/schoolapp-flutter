import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/pending_sync_badge.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/calendar_summary.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La teinte d'une carte de calendrier, selon sa phase (maquette `CalCard`) :
/// brouillon en or, terminé ou archivé en gris, publié en ardoise.
class CalendarCardTint {
  final Color surface;
  final Color border;
  final Color accent;

  const CalendarCardTint._(this.surface, this.border, this.accent);

  static const _draft = CalendarCardTint._(
    AppColors.calendarCardDraftSurface,
    AppColors.calendarCardDraftBorder,
    AppColors.calendarCardDraftAccent,
  );
  static const _archived = CalendarCardTint._(
    AppColors.calendarCardArchivedSurface,
    AppColors.calendarCardArchivedBorder,
    AppColors.calendarCardArchivedAccent,
  );
  static const _published = CalendarCardTint._(
    AppColors.calendarCardPublishedSurface,
    AppColors.calendarCardPublishedBorder,
    AppColors.calendarCardPublishedAccent,
  );

  static CalendarCardTint of(CalendarPhase phase) => switch (phase) {
    CalendarPhase.draft => _draft,
    CalendarPhase.archived || CalendarPhase.ended => _archived,
    CalendarPhase.upcoming || CalendarPhase.inForce => _published,
  };
}

/// Les pastilles d'une carte : statut, cadre national, « n à vérifier », et
/// « en attente d'envoi » s'il reste des gestes sur l'appareil.
class CalendarCardBadges extends StatelessWidget {
  final SchoolCalendar calendar;
  final CalendarPhase phase;
  final CalendarSummary summary;

  const CalendarCardBadges({
    super.key,
    required this.calendar,
    required this.phase,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (IconData icon, Color color) = switch (phase) {
      CalendarPhase.draft => (Icons.edit_outlined, AppColors.calendarDraftInk),
      CalendarPhase.upcoming => (
        Icons.schedule_outlined,
        AppColors.bleuArdoise,
      ),
      CalendarPhase.inForce => (
        Icons.check_circle_outline,
        AppColors.calendarLiveInk,
      ),
      CalendarPhase.ended => (Icons.check_rounded, AppColors.textMuted),
      CalendarPhase.archived => (Icons.lock_outline, AppColors.textSecondary),
    };
    final toVerify = summary.toVerifyCount;
    return Wrap(
      spacing: AppDimensions.calendarPillGap,
      runSpacing: AppDimensions.calendarPillGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusBadge(
          icon: icon,
          label: CalendarLabels.phase(l10n, phase),
          color: color,
        ),
        calendar.hasFramework
            ? StatusBadge(
                icon: Icons.lock_outline,
                label: l10n.schoolCalendarFrameworkIntegrated,
                color: AppColors.bleuArdoise,
              )
            : StatusBadge(
                icon: Icons.schedule_outlined,
                label: l10n.schoolCalendarFrameworkAwaited,
                color: AppColors.calendarDraftInk,
              ),
        if (toVerify > 0)
          StatusBadge(
            icon: Icons.warning_amber_rounded,
            label: l10n.schoolCalendarToVerifyCount(toVerify),
            color: AppColors.calendarDraftInk,
          ),
        if (summary.pendingCount > 0) const PendingSyncBadge(),
      ],
    );
  }
}

/// La répartition par nature en une fine barre (hors périodes), estompée sur
/// un calendrier archivé. Rien quand l'année n'a encore aucun élément.
class CalendarNatureBar extends StatelessWidget {
  final CalendarSummary summary;
  final bool faded;

  const CalendarNatureBar({
    super.key,
    required this.summary,
    required this.faded,
  });

  @override
  Widget build(BuildContext context) {
    final counts = [
      for (final n in CalendarNature.values)
        if (n != CalendarNature.period && summary.countOf(n) > 0)
          (n, summary.countOf(n)),
    ];
    if (counts.isEmpty) return const SizedBox.shrink();
    return Opacity(
      opacity: faded ? AppDimensions.calendarArchivedBarOpacity : 1,
      child: SizedBox(
        height: AppDimensions.calendarNatureBarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (nature, count)) in counts.indexed) ...[
              if (i > 0) const SizedBox(width: AppDimensions.calendarBandGap),
              Expanded(
                flex: count,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: nature.tone.tone,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(
                        AppDimensions.calendarNatureBarHeight / 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
