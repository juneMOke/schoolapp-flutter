import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_actions_row.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/school_calendar_month_grid.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_month_side.dart';

/// La vue Mois : la grille et la liste du mois ou du jour touché (périodes
/// comprises), à côté dès `sideBySideMin` reçus, dessous en deçà (A15).
class CalendarMonthBody extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;
  final List<CalendarElement> visible;
  final bool canWrite;
  final CalendarActions actions;

  const CalendarMonthBody({
    super.key,
    required this.state,
    required this.cubit,
    required this.visible,
    required this.canWrite,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final month = state.month;
    if (month == null) return const SizedBox.shrink();
    final first = month;
    final last = DateTime.utc(month.year, month.month + 1, 0);
    final day = state.selectedDay;
    final listed = [
      for (final e in visible)
        if (day == null ? e.overlaps(first, last) : e.covers(day)) e,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < AppBreakpoints.calendarMonthCompactMax;
        final narrow =
            constraints.maxWidth < AppBreakpoints.calendarMonthNarrowMax;
        final side = constraints.maxWidth >= AppBreakpoints.sideBySideMin;
        final grid = SchoolCalendarMonthGrid(
          year: month.year,
          month: month.month,
          elements: visible,
          today: state.today,
          compact: compact,
          narrow: narrow,
          selectedDay: day,
          pendingIds: {
            for (final r in state.events)
              if (r.isPending) r.element.id,
          },
          onElementTap: actions.openElement,
          onDayTap: (tapped) => _onDay(tapped, compact),
        );
        final list = CalendarMonthSide(
          month: month,
          day: day,
          elements: listed,
          records: {for (final r in state.events) r.element.id: r},
          scopes: state.scopes,
          today: state.today,
          canWrite: canWrite,
          onOpen: actions.openElement,
          onAdd: actions.addOn,
          onClearDay: () => cubit.selectDay(null),
        );
        if (!side) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              grid,
              const SizedBox(height: AppSpacing.md),
              list,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: grid),
            const SizedBox(width: AppSpacing.md),
            SizedBox(width: AppDimensions.calendarSideListWidth, child: list),
          ],
        );
      },
    );
  }

  /// Compact : le jour se sélectionne (I7). Sinon (I6) : jour libre et droit
  /// d'ajouter → O2 à cette date ; un seul élément → O1 ; plusieurs → la
  /// liste montre ce jour.
  void _onDay(DateTime day, bool compact) {
    if (compact) {
      cubit.selectDay(day);
      return;
    }
    final covering = [
      for (final e in visible)
        if (e.nature != CalendarNature.period && e.covers(day)) e,
    ];
    if (covering.isEmpty) {
      if (canWrite) actions.addOn(CalendarDays.of(day));
    } else if (covering.length == 1) {
      actions.openElement(covering.single);
    } else {
      cubit.selectDay(day);
    }
  }
}
