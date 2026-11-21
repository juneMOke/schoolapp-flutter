import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La source : Tout | National | École.
class CalendarSourceFilterControl extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;

  const CalendarSourceFilterControl({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedTabFilter<CalendarSourceFilter>(
      semanticsLabel: l10n.schoolCalendarSource,
      selected: state.source,
      onSelected: cubit.setSource,
      options: [
        SegmentedTabOption(
          label: l10n.schoolCalendarSourceAll,
          value: CalendarSourceFilter.all,
        ),
        SegmentedTabOption(
          label: l10n.schoolCalendarSourceNational,
          value: CalendarSourceFilter.national,
        ),
        SegmentedTabOption(
          label: l10n.schoolCalendarSourceSchool,
          value: CalendarSourceFilter.school,
        ),
      ],
    );
  }
}

/// Semestres | Trimestres, quand l'école a les deux rythmes (A1).
class CalendarRhythmFilterControl extends StatelessWidget {
  final SchoolCalendarState state;
  final SchoolCalendarCubit cubit;

  const CalendarRhythmFilterControl({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedTabFilter<PeriodRhythm>(
      semanticsLabel: l10n.schoolCalendarPeriod,
      selected: state.effectiveRhythm ?? state.scopes.rhythms.first,
      onSelected: cubit.setRhythm,
      options: [
        SegmentedTabOption(
          label: l10n.schoolCalendarRhythmSemesters,
          value: PeriodRhythm.semester,
        ),
        SegmentedTabOption(
          label: l10n.schoolCalendarRhythmTrimesters,
          value: PeriodRhythm.trimester,
        ),
      ],
    );
  }
}
