import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// ‹ « Juin 2026 » › dans son cadre (maquette `CalDetail`, `monthNav`) :
/// boutons de 44 dp, inactifs aux bornes de l'année scolaire, et « Mois en
/// cours » seulement dans l'année, quand on s'est éloigné du mois du jour.
/// [expand] (téléphone) : toute la largeur, le mois au milieu.
class CalendarMonthNav extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;
  final bool expand;

  const CalendarMonthNav({
    super.key,
    required this.state,
    required this.cubit,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calendar = state.calendar!;
    final month = state.month!;
    final first = DateTime.utc(
      calendar.startDate.year,
      calendar.startDate.month,
    );
    final last = DateTime.utc(calendar.endDate.year, calendar.endDate.month);
    final today = CalendarDays.of(state.today);
    final inYear = CalendarDays.within(
      today,
      calendar.startDate,
      calendar.endDate,
    );
    final thisMonth = DateTime.utc(today.year, today.month);
    final raw = MaterialLocalizations.of(context).formatMonthYear(month);
    final label = Text(
      raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}',
      textAlign: TextAlign.center,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.bleuProfond,
        fontWeight: FontWeight.w700,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(AppDimensions.calendarTabsPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppDimensions.calendarTabsRadius),
        ),
        border: Border.all(color: AppColors.calendarTabsBorder),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            tooltip: l10n.schoolCalendarPreviousMonth,
            onPressed: month.isAfter(first) ? () => cubit.shiftMonth(-1) : null,
          ),
          if (expand)
            Expanded(child: label)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppDimensions.calendarMonthNavLabelMinWidth,
              ),
              child: label,
            ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            tooltip: l10n.schoolCalendarNextMonth,
            onPressed: month.isBefore(last) ? () => cubit.shiftMonth(1) : null,
          ),
          if (inYear && month != thisMonth) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: cubit.showCurrentMonth,
              child: Text(l10n.schoolCalendarCurrentMonth),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      fixedSize: const Size.square(AppDimensions.calendarMonthNavButton),
      minimumSize: const Size.square(AppDimensions.calendarMonthNavButton),
      backgroundColor: AppColors.calendarNavSurface,
      disabledBackgroundColor: AppColors.calendarNavSurface,
      foregroundColor: AppColors.textSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.brSm,
        side: BorderSide(color: AppColors.calendarTabsBorder),
      ),
    ),
  );
}
