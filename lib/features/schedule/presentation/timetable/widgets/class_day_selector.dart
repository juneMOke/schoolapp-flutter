import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_weekday_labels.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_grid_marks.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le sélecteur de jour d'une classe (EDT §4.6 E) : « Lun. / 8 juin / 5 h »
/// (« auj. » pour aujourd'hui, la période pour un jour fermé), le jour choisi
/// en terre cuite. Les six jours se partagent la ligne ; trop étroite, elle
/// défile de côté, chaque jour gardant sa cible de 48 dp.
class ClassDaySelector extends StatelessWidget {
  final List<Weekday> days;
  final Weekday selectedDay;
  final Weekday? today;
  final Map<Weekday, DateTime>? dates;
  final Map<Weekday, int> hours;
  final Map<Weekday, ScheduleClosedDay> closedDays;
  final ValueChanged<Weekday> onDaySelected;

  const ClassDaySelector({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.today,
    required this.dates,
    required this.hours,
    required this.closedDays,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    Widget button(Weekday day) {
      final date = dates?[day];
      final closed = closedDays[day];
      return _DayButton(
        label: ScheduleWeekdayLabels.short(l10n, day),
        date: day == today
            ? l10n.scheduleToday
            : date == null
            ? null
            : ml.formatShortMonthDay(date),
        pill: closed?.header ?? l10n.classTimetableDayHours(hours[day] ?? 0),
        spoken: [
          ScheduleWeekdayLabels.long(l10n, day),
          if (date != null) ml.formatMediumDate(date),
          if (day == today) l10n.scheduleTodaySemantics,
          closed?.header ?? l10n.classTimetableDayHours(hours[day] ?? 0),
        ].join(' · '),
        selected: day == selectedDay,
        today: day == today,
        onTap: () => onDaySelected(day),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final fits =
            (constraints.maxWidth - gap * (days.length - 1)) / days.length >=
            AppDimensions.minTouchTarget;
        if (fits) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, day) in days.indexed) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(child: button(day)),
                ],
              ],
            ),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (i, day) in days.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: AppDimensions.timetableDayButtonMinWidth,
                  child: button(day),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DayButton extends StatelessWidget {
  final String label;
  final String? date;
  final String pill;
  final String spoken;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  const _DayButton({
    required this.label,
    required this.date,
    required this.pill,
    required this.spoken,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? AppColors.textOnDark : AppColors.textPrimary;
    final date = this.date;
    return Semantics(
      button: true,
      selected: selected,
      label: spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              color: selected
                  ? null
                  : today
                  ? AppColors.timetableWarmSurface
                  : AppColors.surfaceRaised,
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.terreCuite, AppColors.terreCuiteDark],
                    )
                  : null,
              border: selected
                  ? null
                  : Border.all(
                      color: today
                          ? AppColors.timetableWarmBorder
                          : AppColors.border,
                    ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.labelMedium.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (date != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      date,
                      maxLines: 1,
                      style: AppTypography.labelSmall.copyWith(
                        color: ink.withValues(
                          alpha: AppDimensions.timetableHeaderCaptionOpacity,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.textOnDark.withValues(
                            alpha: AppDimensions.timetableHeaderClosedVeil,
                          )
                        : AppColors.surfaceAlt,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pill,
                      maxLines: 1,
                      style: AppTextStyles.codeMuted.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
