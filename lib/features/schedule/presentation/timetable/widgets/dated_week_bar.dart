import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_calendar_reader.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La semaine datée (EDT-R17, §4.6 C) : ‹ « Semaine du … au … » ›, boutons
/// de 44 dp bordés, et sous le libellé « Cette semaine » ou « Revenir à cette
/// semaine ». [expand] : toute la ligne (sous 600), le libellé au centre.
class DatedWeekBar extends StatelessWidget {
  final DateTime monday;
  final bool isThisWeek;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onThisWeek;
  final bool expand;

  const DatedWeekBar({
    super.key,
    required this.monday,
    required this.isThisWeek,
    required this.onPrevious,
    required this.onNext,
    required this.onThisWeek,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final saturday = CalendarDays.addDays(monday, 5);
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.classTimetableWeekOf(
            dates.formatShortMonthDay(monday),
            dates.formatShortMonthDay(saturday),
          ),
          textAlign: TextAlign.center,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.bleuProfond,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (isThisWeek)
          Text(
            l10n.classTimetableThisWeek,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          )
        else
          InkWell(
            onTap: onThisWeek,
            borderRadius: AppRadius.brSm,
            child: Text(
              l10n.classTimetableBackToThisWeek,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.terreCuiteInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
    // ‹ et › restent de part et d'autre de la semaine : sur un téléphone à
    // ×1,3, c'est le libellé qui passe à la ligne, jamais une flèche.
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _NavButton(
          icon: Icons.chevron_left,
          tooltip: l10n.classTimetablePreviousWeek,
          onPressed: onPrevious,
        ),
        if (expand)
          Expanded(child: label)
        else
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: label,
            ),
          ),
        _NavButton(
          icon: Icons.chevron_right,
          tooltip: l10n.classTimetableNextWeek,
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// Un bouton ‹ / › de 44 dp, bordé (la zone de toucher atteint 48 dp).
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    constraints: const BoxConstraints.tightFor(
      width: AppDimensions.timetableWeekNavButton,
      height: AppDimensions.timetableWeekNavButton,
    ),
    style: IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: AppColors.bleuProfond,
      backgroundColor: AppColors.surfaceRaised,
      side: const BorderSide(color: AppColors.border),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
    ),
    icon: Icon(icon),
  );
}

/// Les bandeaux de période d'une semaine datée (EDT §4.3, R19, R20) : une
/// carte par période (férié, vacances, examens), aux couleurs du calendrier,
/// liseré gauche ; hors de l'année, « Hors année scolaire · rentrée le … ».
class PeriodBanners extends StatelessWidget {
  final ClassCalendarWeek week;

  const PeriodBanners({super.key, required this.week});

  static const _natures = [
    CalendarNature.publicHoliday,
    CalendarNature.holidayBreak,
    CalendarNature.exam,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (week.calendar == null) {
      final next = week.nextStart;
      return _Banner(
        color: AppColors.textSecondary,
        icon: Icons.event_busy_outlined,
        title: l10n.classTimetableOutOfYear,
        detail: next == null
            ? null
            : l10n.classTimetableNextStart(CalendarLabels.day(context, next)),
      );
    }
    final schoolDays = week.days.where(
      (d) => d.date.weekday != DateTime.sunday,
    );
    final byElement = <String, (CalendarElement, int)>{};
    for (final day in schoolDays) {
      for (final e in day.elements) {
        if (!_natures.contains(e.nature)) continue;
        final known = byElement[e.id];
        byElement[e.id] = (e, (known?.$2 ?? 0) + 1);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (element, count) in byElement.values)
          _Banner(
            color: element.nature.tone.tone,
            icon: element.nature.tone.icon,
            title:
                '${l10n.classTimetablePeriodKind(element.nature.wire)} · ${element.title}',
            detail: [
              count >= schoolDays.length
                  ? l10n.classTimetableWholeWeek
                  : l10n.classTimetablePeriodDays(count),
              CalendarLabels.dates(context, element),
              if (element.nature != CalendarNature.exam)
                l10n.classTimetableNoClasses,
            ].join(' · '),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? detail;

  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    this.detail,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brSm,
      border: Border(
        left: BorderSide(color: color, width: AppSpacing.xs),
      ),
    ),
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyMedium),
              if (detail != null) Text(detail!, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}
