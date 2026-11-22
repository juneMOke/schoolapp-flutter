import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/school_year_progress.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le dégradé du bandeau d'un calendrier selon sa phase (maquette
/// `CalDetail`) : brouillon en terre cuite, archivé en gris, sinon bleu vers
/// brun.
List<Color> calendarBannerColors(CalendarPhase phase) => switch (phase) {
  CalendarPhase.draft => const [
    AppColors.calendarDraftBannerStart,
    AppColors.calendarDraftBannerMid,
    AppColors.calendarDraftBannerEnd,
  ],
  CalendarPhase.archived => const [
    AppColors.calendarArchivedBannerStart,
    AppColors.calendarArchivedBannerEnd,
  ],
  _ => const [
    AppColors.kubaBannerStart,
    AppColors.kubaBannerMid,
    AppColors.calendarHeroEnd,
  ],
};

/// « 44 semaines » : connu même hors de l'année.
String calendarWeeksLabel(AppLocalizations l10n, SchoolCalendar calendar) =>
    l10n.schoolCalendarWeeksCount(
      SchoolYearProgress.weekCountOf(calendar.startDate, calendar.endDate),
    );

/// La période en cours et la prochaine échéance, en texte : « P4 · 2e
/// semestre », « Examens du 2e semestre · dans 5 jours ».
(String, String) calendarBannerLines(
  BuildContext context,
  SchoolYearProgress progress,
) {
  final l10n = AppLocalizations.of(context)!;
  final next = progress.nextDeadline;
  final days = progress.daysUntilNextDeadline;
  return (
    CalendarLabels.period(l10n, progress.currentPeriod) ??
        l10n.schoolCalendarOutOfPeriod,
    next == null
        ? '—'
        : [
            next.title,
            if (days != null) l10n.schoolCalendarInDays(days),
          ].join(' · '),
  );
}

/// Le médaillon du bandeau : l'icône calendrier sur un voile clair.
class CalendarBannerMedallion extends StatelessWidget {
  const CalendarBannerMedallion({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: AppDimensions.calendarDetailMedallion,
    height: AppDimensions.calendarDetailMedallion,
    decoration: BoxDecoration(
      color: AppColors.calendarBannerVeil,
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.calendarBannerVeilBorder),
    ),
    child: const Icon(
      Icons.calendar_today_outlined,
      size: AppDimensions.calendarDetailMedallionIcon,
      color: AppColors.calendarBannerIcon,
    ),
  );
}

/// Le statut sur le bandeau : pastille douce opaque, icône et encre de la
/// phase (maquette `CalStatusPill`).
class CalendarStatusPill extends StatelessWidget {
  final CalendarPhase phase;

  const CalendarStatusPill(this.phase, {super.key});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color ink, Color soft) = switch (phase) {
      CalendarPhase.draft => (
        Icons.edit_outlined,
        AppColors.calendarDraftInk,
        AppColors.calendarDraftSoft,
      ),
      CalendarPhase.upcoming => (
        Icons.schedule_outlined,
        AppColors.bleuArdoise,
        AppColors.bleuArdoiseSoft,
      ),
      CalendarPhase.inForce => (
        Icons.check_circle_outline,
        AppColors.calendarLiveInk,
        AppColors.calendarLiveSoft,
      ),
      CalendarPhase.ended => (
        Icons.check_rounded,
        AppColors.textMuted,
        AppColors.surfaceAlt,
      ),
      CalendarPhase.archived => (
        Icons.lock_outline,
        AppColors.textSecondary,
        AppColors.surfaceAlt,
      ),
    };
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(color: soft, borderRadius: AppRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.calendarBannerSmallIcon, color: ink),
          const SizedBox(width: AppSpacing.xs),
          Text(
            CalendarLabels.phase(l10n, phase),
            style: AppTypography.labelSmall.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// « Cadre national intégré » / « attendu » : pastille voilée, cadenas ou
/// horloge.
class CalendarFrameworkChip extends StatelessWidget {
  final bool integrated;

  const CalendarFrameworkChip({super.key, required this.integrated});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.calendarBannerChip,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            integrated ? Icons.lock_outline : Icons.schedule_outlined,
            size: AppDimensions.calendarBannerSmallIcon,
            color: AppColors.textOnDark,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            integrated
                ? l10n.schoolCalendarFrameworkIntegrated
                : l10n.schoolCalendarFrameworkAwaited,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
