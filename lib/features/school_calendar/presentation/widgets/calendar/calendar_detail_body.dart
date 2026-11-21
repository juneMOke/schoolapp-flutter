import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_actions_row.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_month_body.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/elements/calendar_list_view.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/year/school_calendar_year_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La vue d'un calendrier ouvert : l'année, le mois avec sa liste, ou la
/// liste groupée par mois ; « Aucun élément ne correspond » quand la légende
/// ou la source masquent tout.
class CalendarDetailBody extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;
  final bool canWrite;
  final CalendarActions actions;
  final bool compact;

  const CalendarDetailBody({
    super.key,
    required this.state,
    required this.cubit,
    required this.canWrite,
    required this.actions,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visible = state.visibleElements;
    if (visible.isEmpty && state.allElements.isNotEmpty) {
      return EteeloEmptyResult(
        label: l10n.schoolCalendarEmptyFiltered,
        description: l10n.schoolCalendarEmptyFilteredHint,
        medallionIcon: Icons.filter_alt_off_outlined,
        fullWidthCard: true,
      );
    }
    final calendar = state.calendar!;
    switch (state.view) {
      case CalendarView.year:
        return SchoolCalendarYearGrid(
          months: [
            for (
              var m = DateTime.utc(
                calendar.startDate.year,
                calendar.startDate.month,
              );
              !m.isAfter(calendar.endDate);
              m = DateTime.utc(m.year, m.month + 1)
            )
              m,
          ],
          elements: visible,
          today: state.today,
          compact: compact,
          onMonthTap: cubit.showMonth,
        );
      case CalendarView.list:
        return CalendarListView(
          elements: visible,
          records: {for (final r in state.events) r.element.id: r},
          scopes: state.scopes,
          today: state.today,
          compact: compact,
          onOpen: actions.openElement,
        );
      case CalendarView.month:
        return CalendarMonthBody(
          state: state,
          cubit: cubit,
          visible: visible,
          canWrite: canWrite,
          actions: actions,
        );
    }
  }
}
